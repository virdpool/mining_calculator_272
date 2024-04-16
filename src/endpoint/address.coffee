# {client_failover}    = require "../http_client"

@address_get = (req, cb)->  
  cb new Error "disabled"
  # {address} = req
  # if typeof address != "string"
  #   return cb new Error "bad address"
  # 
  # await client_failover.get_address {address}, defer(err, address); return cb err if err
  # 
  # cb null, {address}

# ###################################################################################################
#    address_list
# ###################################################################################################
state_address_list = require "../daemon/address_list"
endpoint_channel = require "../util/endpoint_channel"

{broadcast_fn} = endpoint_channel @,
  name    : "address_list"
  # interval: 1000
  fn      : (req, cb)->
    {address_list} = state_address_list.last_state
    # only top 1000 most balance
    address_list = address_list.slice(0, 1000)
    cb null, {address_list}

state_address_list.ev.on "change_address_list", ()->
  broadcast_fn()
