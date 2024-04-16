# TODO test

###
usage example
Request_cache = require "../util/request_cache"
block_cache = new Request_cache
@block_get = (req, cb)->
  # check req
  {height} = req
  if typeof height != "number"
    return cb new Error "bad height"
  
  # height == request key
  # do not use await, do not create iced structures, could memleak
  block_cache.wrap height, cb, (cb)->
    # TODO make request
    cb null, "your result"

###

# Прим. map, конечно, медленнее, но у {} столько свойств...
# а еще их будут добавлять
# фиг всё за'sanitize'ишь
# а уязвимости в request'ах это очень-очень печально

class @Request_cache
  # ###################################################################################################
  #    config
  # ###################################################################################################
  # soft - давно не спрашивали - удалить
  # hard - редко спрашивают (реже чем avg) - удалить
  
  entity_soft_limit :  10000
  entity_hard_limit : 100000
  entity_soft_limit_timeout : 60000
  pending_request_limit     : 100
  
  # prefetch
  prefetch_round_limit  : 100
  prefetch_pending_limit: 10000 # хорошие значения == entity_soft_limit или == entity_hard_limit
  prefetch_sort         : true
  
  # error_cache
  # не имеет лимита, просто устаревает через error_timeout
  error_cache       : true
  error_timeout     : 10000
  
  # ###################################################################################################
  #    internal
  # ###################################################################################################
  _value_map         : null
  _entity_count     : 0 # == _value_map key count
  _sum_access_count : 0
  
  _error_map        : null
  _error_list       : []
  
  _key_lock_map     : null
  _pending_request_count : 0 # == _key_lock_map key count
  
  _prefetch_map     : null
  _prefetch_list    : []
  # процессор запросов имеет право сортировать этот массив по request_count
  
  constructor : (opt)->
    obj_set @, opt
    @_value_map     = new Map
    @_error_map     = new Map
    
    @_key_lock_map  = new Map
    
    @_prefetch_map  = new Map
    @_prefetch_list = []
  
  delete : ()->
    @_value_map = null
    @_error_map = null
    @_key_lock_map = null
    @_prefetch_map = null
    @_prefetch_list = null
    return
  
  # ###################################################################################################
  #    basic _value_map stuff
  # ###################################################################################################
  get : (key)->
    return null if !cache_entity = @_value_map.get key
    cache_entity.access_ts = Date.now()
    cache_entity.access_count++
    cache_entity.value
  
  set : (key, value)->
    if !cache_entity = @_value_map.get(key)
      @_value_map.set key, {
        access_ts   : Date.now()
        access_count: 1
        value
      }
      @_entity_count++
      @_sum_access_count++
      @_error_map.delete key
    else
      cache_entity.access_ts = Date.now()
      cache_entity.access_count++
      cache_entity.value = cache_entity
      @_sum_access_count++
    return
  
  # NOTE у _value_map это delete, но delete у нас это деструктор
  remove : (key)->
    if cache_entity = @_value_map.get(key)
      @_entity_count--
      @_sum_access_count -= cache_entity.access_count
    return
  
  # ###################################################################################################
  #    error
  # ###################################################################################################
  get_error : (key)->
    return null if !cache_entity = @_error_map.get key
    cache_entity.value
  
  set_error : (key, err)->
    @_value_map.delete key
    @_error_map.set key, cache_entity = {
      key
      timeout_ts : Date.now() + @error_timeout
    }
    @_error_list.push cache_entity
    return
  
  # ###################################################################################################
  #    prefetch
  # ###################################################################################################
  get_prefetch : (key)->
    if !cache_entity = @_value_map.get key
      # если уже в процессе, то не надо еще и prefetch
      return null if @_key_lock_map.has key
      
      if prefetch_entity = @_prefetch_map.get key
        prefetch_entity.request_count++
        return null
      
      # сильно много prefetch
      return null if @_prefetch_list.length >= @prefetch_pending_limit
      
      @_prefetch_map.set key, prefetch_entity = {
        request_count : 1
        key
      }
      @_prefetch_list.push prefetch_entity
      return null 
    # COPYPASTE inlined PERF
    cache_entity.access_ts = Date.now()
    cache_entity.access_count++
    cache_entity.value
  
  # напоминание. Prefetcher обязуется вызвать для каждого полученного значения prefetch_set(key, value, err)
  prefetch_list_get : (limit = @prefetch_round_limit, sort = @prefetch_sort)->
    limit = Math.min limit, @pending_request_limit - @_pending_request_count
    return [] if limit <= 0
    
    if @_prefetch_list.length < limit
      ret = @_prefetch_list
      @_prefetch_list = []
      @_prefetch_map.clear()
      return @_prefetch_key_list_lock ret
    
    if sort
      @_prefetch_list.sort (a,b)->-(a.request_count - b.request_count)
    
    ret = @_prefetch_list.slice 0, limit
    @_prefetch_list = @_prefetch_list.slice limit
    for v in ret
      @_prefetch_map.delete v.key
    
    return @_prefetch_key_list_lock ret
  
  _prefetch_key_list_lock : (_prefetch_list)->
    filter_prefetch_list = []
    for prefetch_entity in _prefetch_list
      {key} = prefetch_entity
      
      # уже есть результат, не надо спрашивать
      continue if @_value_map.has key
      continue if @_error_map.has key
      
      # не надо давать prefetcher'у то, что и так уже запрашивается
      continue if @_key_lock_map.has key
      
      @_pending_request_count++
      @_key_lock_map.set key, {
        cb_list : []
      }
      filter_prefetch_list.push prefetch_entity
    
    filter_prefetch_list
  
  prefetch_set : (key, value, err)->
    if !err
      @set key, value
    else @error_cache
      @set_error key, err
    return if !key_lock_entity = @_key_lock_map.get key
    
    @_pending_request_count--
    @_key_lock_map.delete key
    
    for cb in key_lock_entity.cb_list
      try
        cb err, value
      catch err2
        perr "prefetch_set catch err", err2
    
    return
  
  # ###################################################################################################
  #    wrap и компания
  # ###################################################################################################
  limit_check : ()->
    if @_entity_count > @entity_soft_limit
      remove_count = @_entity_count - @entity_soft_limit
      threshold_ts = Date.now() - @entity_soft_limit_timeout
      
      remove_key_list = []
      # forEach не подходит т.к. нельзя сделать break
      `
      for (let pair of this._value_map) {
        let [key,value] = pair;
        if (value.access_ts < threshold_ts) {
          remove_key_list.push(key);
          this._sum_access_count -= value.access_count;
          if (remove_key_list.length >= remove_count) break;
        }
      }
      `
      for key in remove_key_list
        @_value_map.delete key
      @_entity_count -= remove_key_list.length
    
    if @_entity_count > @entity_hard_limit
      remove_count = @_entity_count - @entity_hard_limit
      # итерация по 100k элементам в критический момент это очень долго, потому быстро посчитали и вперед
      # И это даже не оценка а реально правильное значение (если нигде не продолбать обновить счетчики)
      threshold_access_count = @_sum_access_count / @_entity_count
      
      remove_key_list = []
      `
      for (let pair of this._value_map) {
        let [key,value] = pair;
        if (value.access_count <= threshold_access_count) {
          remove_key_list.push(key);
          this._sum_access_count -= value.access_count;
          if (remove_key_list.length >= remove_count) break;
        }
      }
      `
      for key in remove_key_list
        @_value_map.delete key
      @_entity_count -= remove_key_list.length
    
    if @error_cache
      now = Date.now()
      # fast check
      if @_error_list.length and @_error_list[0].timeout_ts <= now
        # fack check чтобы не делать вот этот alloc
        remove_key_list = []
        # _error_list сортирован по timeout_ts
        for cache_entity in @_error_list
          if cache_entity.timeout_ts <= now
            remove_key_list.push cache_entity.key
          else
            break
        
        if remove_key_list.length
          @_error_list = @_error_list.slice remove_key_list.length
          for key in remove_key_list
            @_error_map.delete key
    
    return
  
  wrap : (key, cb, nest)->
    if ret = @get key
      return cb null, ret
    
    if key_lock_entity = @_key_lock_map.get key
      return key_lock_entity.cb_list.push cb
    
    if @_pending_request_count >= @pending_request_limit
      return cb new Error "too much requests"
    
    @_pending_request_count++
    @_key_lock_map.set key, key_lock_entity =
      cb_list : [cb]
    
    await rest defer(err, value)
    
    @prefetch_set key, value, err
    @limit_check()
    return
