window.ws_mod_sub = (ws, wsrs)->
  ws.__sub_list = []
  ws.__sub_uid = 0
  ws.sub = (opt, handler)->
    sub_id = ws.__sub_uid++
    opt.sub.sub_id = sub_id
    opt.unsub.sub_id = sub_id
    
    ws.on "data", opt.handler = (data)->
      return if data.switch != opt.switch
      handler data
    
    if !ws.__sub_list.has opt
      ws.__sub_list.push opt
      wsrs.request clone(opt.sub), (err, data)->
        perr err if err
        opt.on_sub? err, data
    
    ()->
      ws.unsub opt, handler
  
  ws.unsub = (opt)->
    ws.off "data", opt.handler
    
    ws.__sub_list.remove opt
    wsrs.request clone(opt.unsub), (err)->perr err if err
    return
  
  ws.on "reconnect", ()->
    for opt in ws.__sub_list
      ws.send opt.sub
    return
  return
