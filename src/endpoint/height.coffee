state_height = require "../daemon/height"
endpoint_channel = require "../util/endpoint_channel"

{broadcast_fn} = endpoint_channel @,
  name    : "height"
  # interval: 500
  fn      : (req, cb)->
    cb null, {height: state_height.last_state.height}

state_height.ev.on "change_height", ()->
  broadcast_fn()
