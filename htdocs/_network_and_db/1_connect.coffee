if location.protocol == "https:"
  ws_back_url = "wss://#{location.hostname}/ws"
else if /^192\.168\./.test location.hostname
  ws_back_url = "ws://#{location.hostname}:9101"
else
  ws_back_url = "ws://#{location.hostname}:1981"
window.ws_back  = new Websocket_wrap ws_back_url
window.wsrs_back= new Ws_request_service ws_back 
ws_mod_sub ws_back, wsrs_back

do ()->
  loop
    await setTimeout defer(), 1000
    await wsrs_back.request {switch: "ping"}, defer(err);
    perr err if err
