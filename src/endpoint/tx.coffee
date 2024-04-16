sha2      = require "../util/sha2"
base64url = require "../util/base64url"
{client_failover}  = require "../http_client"

# TODO cache_wrap

# TODO limit WIP requests
# TODO ban IP too much requests
# TODO ban IP too much uncached requests

# TODO Map?
tx_hash = {}
@tx_get = (req, cb)->  
  {txid} = req
  if typeof txid != "string"
    return cb new Error "bad txid"
  
  if res = tx_hash[txid]
    res.last_use_ts = Date.now()
    return cb null, {tx:res.tx}
  await client_failover.get_tx {txid}, defer(err, tx); return cb err if err
  
  tx.owner_address = base64url.encode sha2 base64url.decode tx.owner
  tx_hash[txid] = {
    tx
    last_use_ts : Date.now()
  }
  
  cb null, {tx}
  # TODO cache_clear_tick

@tx_get_bulk = (req, cb)->  
  {txid_list} = req
  unless txid_list instanceof Array
    return cb new Error "bad txid_list"
  
  txid_hash = {}
  now = Date.now()
  for txid in txid_list
    if typeof txid != "string"
      return cb new Error "bad txid"
  
    if res = tx_hash[txid]
      res.last_use_ts = now
      txid_hash[txid] = res.tx
  
  cb null, {txid_hash}
  # TODO cache_clear_tick

# ###################################################################################################
# TODO separate class
# "LRU" cache
# может вылетать за max_entity_count
# убивает только старые entity AND если их больше max_entity_count
# TODO max_entity_count_force_kill_watermark
# точка когда начинаем убивать entity с access count <= avg пока не будет меньше max_entity_count_force_kill_watermark

max_entity_count = 10000
remove_key_watch_interval = 10000
remove_key_list_limit = 100
remove_key_timeout = 60000 # TODO config
tx_hash_count_refresh_inverval = 1000

# DEBUG
# max_entity_count = 10
# remove_key_watch_interval = 2000
# remove_key_timeout = 1000
# remove_key_list_limit = 1

tx_hash_count_last_ts = 0
tx_hash_count = 0
remove_key_list = []
loop
  if remove_key_list.length < remove_key_list_limit
    await setTimeout defer(), remove_key_watch_interval
  remove_key_list = []
  
  if Date.now() - tx_hash_count_last_ts > tx_hash_count_refresh_inverval
    tx_hash_count = h_count(tx_hash)
    # p "h_count(tx_hash)", h_count(tx_hash), Object.keys(tx_hash).join()
  
  # p "tx_hash_count", tx_hash_count
  continue if tx_hash_count <= max_entity_count
  max_remove_count = Math.min max_entity_count - tx_hash_count, remove_key_list_limit
  
  threshold_ts = Date.now() - remove_key_timeout
  for k,v of tx_hash
    if v.last_use_ts < threshold_ts
      remove_key_list.push k
      break if remove_key_list.length >= max_remove_count
  
  for key in remove_key_list
    delete tx_hash[key]
    tx_hash_count--
