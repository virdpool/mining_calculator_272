{client_failover}    = require "../http_client"

endpoint_channel = require "../util/endpoint_channel"

# TODO full peer list (recursive)
# ЗАКОСТЫЛЕНО
{broadcast_fn} = endpoint_channel @,
  name    : "peer_list"
  interval: 10000
  fn      : (req, cb)->
    await client_failover.get_peer_list {}, defer(err, peer_list); return cb err if err
    
    cb null, {peer_list}
