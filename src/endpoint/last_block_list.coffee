state_last_block_list = require "../daemon/last_block_list"
endpoint_channel = require "../util/endpoint_channel"

{broadcast_fn} = endpoint_channel @,
  name    : "last_block_list"
  # interval: 1000
  fn      : (req, cb)->
    last_block_list = []
    
    if !list = state_last_block_list.last_state.last_block_list
      last_block_list = null
    else
      for block in list
        last_block_list.push {
          height        : block.height
          # hash          : block.hash
          indep_hash    : block.indep_hash
          timestamp     : block.timestamp
          block_size    : block.block_size
          weave_size    : block.weave_size
          reward_addr   : block.reward_addr
          diff          : block.diff # нуждается в пересчете
          txs_count     : block.txs.length
          reward        : block.reward
        }
    
    cb null, {last_block_list}

state_last_block_list.ev.on "change_last_block_list", ()->
  broadcast_fn()
