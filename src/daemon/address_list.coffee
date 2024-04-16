module = @
@ev = ev = require "./ev"
require "../util/bn"
{client_failover}    = require "../http_client"
config      = require "../config"
state_height= require "./height"

@last_state = {address_list : null}
@block_hash = {}
  
# ###################################################################################################
#    watch
# ###################################################################################################
update_address_list = (opt, cb)->
  await client_failover.get_address_list {}, defer(err, address_list); return cb err if err
  
  address_list.sort (a,b)->-(BigInt(a.balance) - BigInt(b.balance)).toNumber()
  module.last_state.address_list = address_list
  ev.dispatch "change_address_list"
  
  cb null

#await update_address_list {}, defer(err); perr err if err

# TEMP disabled
# ev.on "change_hash", ()->
  # update_address_list {}, (err)->perr err if err
