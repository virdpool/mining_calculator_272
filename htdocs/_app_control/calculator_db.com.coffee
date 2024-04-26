module.exports =
  # ###################################################################################################
  #    network
  # ###################################################################################################
  # TODO proper refresh
  block_reward : 0.73
  network_hashrate : 2303940
  pool_fee : 0.04
  blocks_per_day : 24*60*60/129
  stat_block_count : 119
  network_weave_size : 179072611426550
  
  # ###################################################################################################
  #    user controllable
  # ###################################################################################################
  # hashrate, hdd
  mode            : "hashrate"
  #mode            : "hdd" # dev
  hashrate        : 2000
  exchange_rate   : 34.43
  include_pool_fee: true
  hdd_config      : []
  # only mode hdd
  weave_size_tb   : Math.round (179072611426550 * 0.8)/1000**4
  
  full_replica_count : 0
  part_replica_count : 0
  
  # ###################################################################################################
  #    calculated
  # ###################################################################################################
  block_prob_per_day : 0
  profit_per_day : 0
  
  on_unmount_list : []    
  is_mounted : true
  
  mount : ()->
    @hashrate_related_recalc()
    @exchange_rate_refresh()
    @hdd_config = []
    try
      @hdd_config = JSON.parse localStorage.hdd_config
    catch err
    
    if @hdd_config.length == 0
      @hdd_config.push {
        size_tb   : 4
        count     : 10
        read_mb_s : 150
      }
    @on_unmount_list = []
    simple_sub_endpoint @, "last_block_list", (res)=>
      if res.last_block_list
        for block in res.last_block_list
          block_height_hash[block.height] = block

        block_reward_sum = 0
        block_reward_count = 0
        for block in res.last_block_list
          continue if !block.reward
          block_reward_count++
          block_reward_sum += +block.reward
        @set_state {
          block_reward : winston_to_ar block_reward_sum/block_reward_count
          block_reward_count
        }
        @block_reward = winston_to_ar block_reward_sum/block_reward_count
        @force_update()
        call_later ()=>
          @economics_recalc()
          @force_update()


      @block_data_refresh()
      return

    simple_sub_endpoint @, "height", (res)=>
      @set_state {
        height : res.height
      }
      @block_data_refresh res.height
      call_later ()=>
        @economics_recalc() 
        @force_update()
  
  block_data_refresh : (height = @state.height)->
    for i in [0 ... 100]
      break if block = block_height_hash[height]
      height--
    if block
      net_hashrate_v1 = 0
      count = 0
      prev_block = null
      real_block_time_sum = 0
      hash_count_sum = 0
      for k, block of block_height_hash
        if prev_block
          real_block_time = block.timestamp - prev_block.timestamp

          hash_count = diff_to_avg_hash_count block.diff
          hash_count_sum  += hash_count
          real_block_time_sum += real_block_time
          net_hashrate_v1 += hash_count/block_time
          count++
        prev_block = block

      net_hashrate = hash_count_sum/real_block_time_sum
      net_hashrate_v1 /= count
      @set_state {
        net_hashrate
        net_hashrate_v1
        # hash_count_per_block_avg: net_hashrate/(real_block_time_sum / count)
        hash_count_per_block_avg: hash_count_sum / count
        real_block_time       : real_block_time_sum/count
        weave_size            : block.weave_size
        weave_size_is_loading : false
        weave_size_load_error : false
      }
      @network_hashrate = Math.round net_hashrate
      @weave_size = block.weave_size
      @weave_size = count
      @hashrate_related_recalc()
    @force_update()
  exchange_rate_refresh : ()->
    # NOTE we assume 1 USDT == 1 USD
    # fetch("https://api.binance.com/api/v3/avgPrice?symbol=ARUSDT").cb (err,res)=>
    fetch("https://api.binance.com/api/v3/ticker/24hr?symbol=ARUSDT").cb (err,res)=>
      if err
        @set_state
          exchange_rate_is_loading : false
          exchange_rate_load_error : true
        return
      res.text().cb (err, res)=>
        if err                                                                                
          @set_state
            exchange_rate_is_loading : false
            exchange_rate_load_error : true
          return
        try
          data = JSON.parse res
        catch err
          @set_state
            exchange_rate_is_loading : false
            exchange_rate_load_error : true
          perr "BAD JSON binance #{res}"                                                      
          return

        # value = +data.price                                                                 
        value = +data.weightedAvgPrice
        if isFinite value
          @set_state
            exchange_rate : +value.toFixed 2
            exchange_rate_is_loading : false
            exchange_rate_load_error : false
          @exchange_rate = +value.toFixed 2
          @economics_recalc()
          @force_update()
        else
          @set_state
            exchange_rate_is_loading : false
            exchange_rate_load_error : true
          perr data
          # perr "bad value price #{data.price}"
          perr "bad value price #{data.weightedAvgPrice}"

  update_metrics : ()->
    do ()=>
      @set_state
        max_storage_is_loading_start : true
      old_max_available_data_size = 0
      while old_max_available_data_size != @state.max_available_data_size
        old_max_available_data_size = @state.max_available_data_size
        for i in [0 ... 4]
          puts "_update_metrics", @state.max_available_data_size//1000**3
          @_update_metrics() # cb?
          await setTimeout defer(), 1000
      @set_state
        max_storage_is_loading_start : false
      return
    return


  _update_metrics : ()->
    fetch("https://arweave.net/metrics").cb (err,res)=>
      if err
        @set_state
          max_storage_is_loading : false
          max_storage_load_error : true
        return
      res.text().cb (err, res)=>
        if err
          @set_state
            max_storage_is_loading : false
            max_storage_load_error : true
          return
        list = res.split("\n").filter (t)->
          return false if t[0] == "#"
          /v2_index_data_size /.test t

        if list.length
          value = +list.last().split(" ")[1]
          if isFinite value
            # puts "value", value, list
            # FUCK failover
            # arweave.net может вернуть ояебу значение
            value = Math.max value, @state.max_available_data_size
            @set_state
              max_available_data_size: value
              max_storage_is_loading : false
              max_storage_load_error : false
            call_later ()=>@calculate_spora_hashrate()
          else
            @set_state
              max_storage_is_loading : false
              max_storage_load_error : true                                    
            perr "bad value v2_index_data_size #{value}"                       
        else
          @set_state
            max_storage_is_loading : false
            max_storage_load_error : true
          perr "missing v2_index_data_size"
  ###########
  
  hashrate_related_recalc : ()->
    hash_count_per_block_avg = 24 * 60 * 60 * @network_hashrate / @blocks_per_day # TEMP
    p_per_hash = 1 / hash_count_per_block_avg
    @block_prob_per_day = 1 - Math.pow(1 - p_per_hash, 24 * 60 * 60 * @hashrate)
    @economics_recalc()
  
  hashrate_recalc_from_hdd : ()->
    PARTITION_SIZE = (3.6e12 / 1000**4)
    
    total_size_tb   = 0
    total_read_mb_s = 0
    max_read_mb_s   = 0
    partition_count = 0
    for hdd in @hdd_config
      total_size_tb   += hdd.count * hdd.size_tb
      max_read_per_hdd = 200 * hdd.size_tb / 4 
      total_read_mb_s += hdd.count * Math.min hdd.read_mb_s, max_read_per_hdd
      max_read_mb_s   += hdd.count * max_read_per_hdd
      partition_count += hdd.count * hdd.size_tb / 4 
    
    # network max data
    network_partition_count = Math.floor @network_weave_size / 3.6e12
    available_network_size_tb = network_partition_count * PARTITION_SIZE
    
    # available unique data
    weave_size_tb  = Math.min @weave_size_tb, total_size_tb, available_network_size_tb
    available_unique_partition_count = weave_size_tb / PARTITION_SIZE
    
    # != @network_weave_size; excluding last incomplete partition
    weave_rate_max = weave_size_tb/available_network_size_tb
    weave_rate_max = Math.min weave_rate_max, 1
    
    # "full". == my full
    full_replica_count_float = total_size_tb / weave_size_tb
    full_replica_count = Math.floor full_replica_count_float
    part_replica_count = full_replica_count_float - full_replica_count
    weave_rate_part = part_replica_count * weave_rate_max
    
    @full_replica_count = full_replica_count
    @part_replica_count = part_replica_count
    
    @hashrate =
      (4 * network_partition_count * weave_rate_max  + 400 * network_partition_count * weave_rate_max  * weave_rate_max ) * full_replica_count +
      (4 * network_partition_count * weave_rate_part + 400 * network_partition_count * weave_rate_part * weave_rate_part)

    @hashrate *= total_read_mb_s/max_read_mb_s
    
    if @hashrate > 1
      @hashrate = Math.round @hashrate
    else
      @hashrate = Math.round(@hashrate*100)/100
    
    @hashrate_related_recalc()
  
  economics_recalc : ()->
    rate = @hashrate / @network_hashrate
    @profit_per_day = rate * @block_reward * @blocks_per_day
  
  render : ()->
    Calculator_view {
      # ###################################################################################################
      #    network
      # ###################################################################################################
      block_reward    : @block_reward
      network_hashrate: @network_hashrate
      pool_fee        : @pool_fee
      stat_block_count: @stat_block_count
      network_weave_size: @network_weave_size
      
      # ###################################################################################################
      #    user controllable
      # ###################################################################################################
      mode : @mode
      on_change_mode : (value)=>
        @mode = value
        if @mode == "hdd"
          @hashrate_recalc_from_hdd()
        @force_update()
      
      hashrate : @hashrate
      on_change_hashrate : (value)=>
        @hashrate = value
        @hashrate_related_recalc()
        @force_update()
      
      full_replica_count : @full_replica_count
      part_replica_count : @part_replica_count
      
      exchange_rate : @exchange_rate
      on_change_exchange_rate : (value)=>
        @exchange_rate = value
        @force_update()
      on_exchange_rate_refresh : ()=>
        @exchange_rate_refresh()
        @force_update()
      
      include_pool_fee : @include_pool_fee
      on_change_include_pool_fee : (value)=>
        @include_pool_fee = value
        @force_update()
      
      hdd_config : @hdd_config
      on_change_hdd_config : ()=>
        localStorage.hdd_config = JSON.stringify @hdd_config
        @hashrate_recalc_from_hdd()
        @force_update()
      # TODO load/save
      
      weave_size_tb : @weave_size_tb
      on_change_weave_size_tb : (value)=>
        @weave_size_tb = value
        @hashrate_recalc_from_hdd()
        @force_update()
      
      # ###################################################################################################
      #    calculated
      # ###################################################################################################
      block_prob_per_day: @block_prob_per_day
      profit_per_day    : @profit_per_day
    }
