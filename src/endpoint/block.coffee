{client_failover}    = require "../http_client"

# TODO cache_wrap

# TODO limit WIP requests
# TODO ban IP too much requests
# TODO cache (только по indep_hash)
# TODO cache по height, но с timeout'ом
# TODO ban IP too much uncached requests

@block_get = (req, cb)->  
  {height, hash} = req
  if height?
    if typeof height != "number"
      return cb new Error "bad height"
    
    await client_failover.get_block {height}, defer(err, block); return cb err if err
  else if hash?
    if typeof hash != "string"
      return cb new Error "bad hash"
    
    await client_failover.get_block {hash}, defer(err, block); return cb err if err
  else
    perr "req", req
    return cb new Error "bad request"
  
  cb null, {block}
