window.address_get = (address, cb)->
  await wsrs_back.request {switch: "address_get", address}, defer(err, res); return cb err if err
  
  cb null, res.address
