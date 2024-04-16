# TODO LRU
window.block_height_hash = {}

window.block_get_by_height = (height, cb)->
  await wsrs_back.request {switch: "block_get", height}, defer(err, res); return cb err if err
  block_height_hash[res.block.height] = res.block
  cb null, res.block

window.block_get_by_hash = (hash, cb)->
  await wsrs_back.request {switch: "block_get", hash}, defer(err, res); return cb err if err
  block_height_hash[res.block.height] = res.block
  cb null, res.block
