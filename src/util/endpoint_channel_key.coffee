module.exports = (mod, opt)->
  {
    name
    fn
    req
    req2key
  } = opt
  opt.req ?= {}
  if !req2key
    throw new Error "missing req2key for #{name}"
  
  key_connection_list_hash  = {}
  key_last_json_msg_hash    = {}
  broadcast_connection_list = []
  
  unsub = (req, connection)->
    connection["__#{name}_global_sub_id_hash"] ?= {}
    delete connection["__#{name}_global_sub_id_hash"][req.sub_id]
    if 0 == h_count connection["__#{name}_global_sub_id_hash"]
      broadcast_connection_list.remove connection
    return
  
  if opt.global # global_ep
    mod["#{name}_global_sub"] = (req, cb, http_req, http_res, ws_send, connection)->
      if !connection?
        return cb new Error "#{name}_global_sub can be only applied to websocket request"
      
      connection["__#{name}_global_sub_id_hash"] ?= {}
      connection["__#{name}_global_sub_id_hash"][req.sub_id] = true
      
      broadcast_connection_list.upush connection
      
      connection.on "close", ()->
        # kill all subs
        broadcast_connection_list.remove connection
      
      cb null
    
    mod["#{name}_global_unsub"] = (req, cb, http_req, http_res, ws_send, connection)->
      if !connection?
        return cb new Error "#{name}_global_unsub can be only applied to websocket request"
      
      connection["__#{name}_global_sub_id_hash"] ?= {}
      delete connection["__#{name}_global_sub_id_hash"][req.sub_id]
      if 0 == h_count connection["__#{name}_global_sub_id_hash"]
        broadcast_connection_list.remove connection
      
      cb null
  
  mod["#{name}_sub"] = (req, cb, http_req, http_res, ws_send, connection)->
    if !connection?
      return cb new Error "#{name}_sub can be only applied to websocket request"
    
    await opt.req2key req, defer(err, key); return cb err if err
    
    connection["__#{name}_sub_id_hash"] ?= {}
    connection["__#{name}_sub_id_hash"][key] ?= {}
    connection["__#{name}_sub_id_hash"][key][req.sub_id] = true
      
    key_connection_list_hash[key] ?= []
    key_connection_list_hash[key].upush connection
    
    connection.on "close", ()->
      # kill all subs
      key_connection_list_hash[key]?.remove connection
    
    
    last_msg_json = key_last_json_msg_hash[key]
    if last_msg_json?
      connection.send last_msg_json
    else if fn?
      await fn key, req, defer(err, res); return cb err if err
      if res?
        key_last_json_msg_hash[key] = last_msg_json = JSON.stringify
          switch : "#{name}_stream"
          res    : res
        connection.send last_msg_json
    
    cb null
  
  mod["#{name}_unsub"] = (req, cb, http_req, http_res, ws_send, connection)->
    if !connection?
      return cb new Error "#{name}_unsub can be only applied to websocket request"
    
    await opt.req2key req, defer(err, key); return cb err if err
    
    connection["__#{name}_sub_id_hash"] ?= {}
    if connection["__#{name}_sub_id_hash"][key]
      delete connection["__#{name}_sub_id_hash"][key][req.sub_id]
      if 0 == h_count connection["__#{name}_sub_id_hash"][key]
        key_connection_list_hash[key]?.remove connection
    
    cb null
  
  
  broadcast_key_fn = (key, msg)->
    key_last_json_msg_hash[key] = last_msg_json = JSON.stringify
      switch : "#{name}_stream"
      res    : msg
    
    # TODO do not send 1 message 2 times at same connection (direct sub + broadcast sub)
    
    for loc_con in key_connection_list_hash[key] ? []
      try
        loc_con.send last_msg_json
      catch err
        perr err
    
    for loc_con in broadcast_connection_list
      try
        loc_con.send last_msg_json
      catch err
        perr err
    
    return
  return {broadcast_key_fn}
