module.exports =
  render : ()->
    max_bn = bn_shl BigInt(1), BigInt(256)
    value_bn = BigInt @props.value
    
    # arweave source based
    rest = bn_sub max_bn, value_bn
    res = 256 - Math.log2 +rest.toString()
    fmt_str = res.toFixed 2
    
    avg_hash_count = diff_to_avg_hash_count @props.value
    
    Tooltip {
      tooltip_render : ()=>
        div {
          style :
            background  : "#fff"
            padding     : 5
            borderRadius: 5
            border      : "1px solid #000"
            fontFamily  : "monospace"
            whiteSpace  : "pre"
        }
          div value_bn.toString(16)
          div "  avg hash count for block #{avg_hash_count.toFixed(0).rjust 10}"
          div "instant net hashrate (OLD) #{(avg_hash_count/block_time).toFixed(0).rjust 10}"
          if @props.block and @props.prev_block
            real_block_time = @props.block.timestamp - @props.prev_block.timestamp
            div   "      instant net hashrate #{(avg_hash_count/real_block_time).toFixed(0).rjust 10}"
    }
      span fmt_str
