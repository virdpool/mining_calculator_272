# TODO LRU
window.tx_hash = {}

# TODO limit lock mixin
window.tx_get = (txid, cb)->
  if res = tx_hash[txid]
    return cb null, res
  await wsrs_back.request {switch: "tx_get", txid}, defer(err, res_tx); return cb err if err
  tx_hash[txid] = tx = res_tx.tx
  cb null, tx

window.tx_get_bulk = (txid_list, cb)->
  filter_txid_list = []
  txid_hash = {}
  for txid in txid_list
    if res = tx_hash[txid]
      txid_hash[txid] = res
    else
      filter_txid_list.push txid
  
  if filter_txid_list.length
    await wsrs_back.request {switch: "tx_get_bulk", txid_list:filter_txid_list}, defer(err, res); return cb err if err
  
  obj_set tx_hash, res.txid_hash
  obj_set txid_hash, res.txid_hash
  
  cb null, txid_hash
