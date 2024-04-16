module = @
@ev = ev = require "./ev"
config = require "../config"
{client_failover} = require "../http_client"

@last_state = {
  height : null
  curr_block_hash: null
}
first = true
loop
  if !first
    await setTimeout defer(), config.height_poll_ts
  first = false
  
  for client in client_failover.client_list
    await client.get_info {}, defer(err, res)
    if err
      perr client.url, err.message
      continue
    
    if !res
      perr "!res"
      continue
    
    continue if res.height == -1
    
    res.curr_block_hash = res.current
    
    {last_state} = @
    if last_state
      if last_state.height > res.height
        continue
    @last_state = res
    
    if last_state.height != res.height
      ev.dispatch "change_height"
    
    if last_state.current != res.current
      ev.dispatch "change_hash"
  
