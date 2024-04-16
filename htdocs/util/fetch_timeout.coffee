window.fetch_timeout = (opt, cb)->
  {
    url
    timeout
    body
  } = opt
  timeout ?= 30000
  body ?= true
  
  controller = new AbortController()
  is_ended = false
  setTimeout ()->
    return if is_ended
    controller.abort()
  , timeout
  
  await fetch(url, signal:controller.signal).cb defer(err, res); return cb err if err
  if body
    await res.text().cb defer(err, body); return cb err if err
    cb null, body, res
  else
    cb null, res
