module = @
fs = require "fs"
@ev = ev = require "./ev"
{client_failover}    = require "../http_client"
config      = require "../config"
state_height= require "./height"
require "lock_mixin"

@last_state = {last_block_list : null}
@block_hash = {}

try 
  @block_hash = JSON.parse fs.readFileSync "block_sync.json"
catch err
  perr err.message
  
# ###################################################################################################
#    watch
# ###################################################################################################
get_block = (opt, cb)->
  {hash} = opt
  return cb null, ret if ret = module.block_hash[hash]
  # TODO adequate throttle
  # DUMB
  await setTimeout defer(), 1000
  
  await client_failover.get_block {hash}, defer(err, block); return cb err if err
  delete block.poa
  module.block_hash[hash] = block
  fs.writeFileSync "block_sync.json", JSON.stringify module.block_hash
  cb null, block

update_throttle_ts = 100

lock = new Lock_mixin
ev.on "change_hash", ()->
  cb = ()->
  await lock.wrap cb, defer(cb)
  list = []
  
  loc_opt =
    hash : state_height.last_state.curr_block_hash
  
  # p "DEBUG 1"
  await get_block loc_opt, defer(err, block)
  if err
    perr "last_block_list ERROR", err.message
    cb()
    return
  
  list.push block
  prev_block_list = module.last_state.last_block_list
  module.last_state.last_block_list = list
  # prevent blink on add new block
  # ev.dispatch "change_last_block_list"
  
  last_update_ts = Date.now()
  
  limit = 3
  while list.length < config.last_block_list_count
    break if !prev_block_hash = list.last().previous_block
    
    loc_opt =
      hash : prev_block_hash
    
    if !module.block_hash[prev_block_hash]
      limit--
      # p "DEBUG 2", prev_block_hash
    await get_block loc_opt, defer(err, block)
    if err
      perr "last_block_list ERROR", err.message
      cb()
      return
    
    list.push block
    now = Date.now()
    if now - last_update_ts > update_throttle_ts
      last_update_ts = now
      ev.dispatch "change_last_block_list"
    break if limit <= 0
  
  
  if prev_block_list and last_block = list[0]
    for block in prev_block_list
      # if !list.has block # slow
      if block.height - last_block.height > 2*config.last_block_list_count
        delete module.block_hash[block.hash]
  
  ev.dispatch "change_last_block_list"
  
  # p "DEBUG 3"
  # continuation
  if list.length < config.last_block_list_count
    cb()
    await setTimeout defer(), 1000
    ev.dispatch "change_hash"
  else
    # missing reward update
    limit = 5
    for block in list
      if !block.reward
        p "try refresh reward", block.indep_hash
        hash = block.indep_hash
        for client in client_failover.client_list
          await client.get_block {hash}, defer(err, block_res);
          if err
            perr err.message, client.url
            continue
          if block_res.reward
            delete block_res.poa
            module.block_hash[hash] = block_res
            fs.writeFileSync "block_sync.json", JSON.stringify module.block_hash
            ev.dispatch "change_last_block_list"
            break
        # only 1 block
        limit--
        break if limit <= 0
    cb()
