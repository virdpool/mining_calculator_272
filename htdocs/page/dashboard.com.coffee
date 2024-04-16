module.exports =
  state :
    height  : null
    
  
  on_unmount_list : []
  is_mounted : true
  mount : ()->
    @on_unmount_list = []
    simple_sub_endpoint @, "last_block_list", (res)=>
      @force_update()
    simple_sub_endpoint @, "height", (res)=>
      @set_state {
        height : res.height
      }
      # костыль для обновления hashrate
      loop
        await setTimeout defer(), 100
        break if block_height_hash[@state.height]
      @force_update()
  
  unmount : ()->
    @is_mounted = false
    for fn in @on_unmount_list
      try
        fn()
      catch err
        perr err
    return
  
  render : ()->
    max_bn = bn_shl BigInt(1), BigInt(256)
    diff_format = (diff)->
      rest_bn = bn_sub max_bn, BigInt(diff)
      res = +max_bn.toString()/+rest_bn.toString()
      res /= 128 # default diff
      Math.log2(res).toFixed 2
    Page_wrap {value:"dashboard"}
      div {
        style:
          display   : "flex"
          direction : "column"
          gap       : 10
          marginBottom : 10
      }
        Group {
          label: "Height"
          style:
            width : 200
            height: 100
          
          body_style:
            fontSize  : 20
            background: "#e0e0ea"
            textAlign : "center"
        }
          if @state.height?
            span @state.height
          else
            Spinner {}
        Group {
          label: "Net hashrate"
          style:
            width : 200
            height: 100
          
          body_style:
            fontSize  : 20
            background: "#e0e0ea"
            textAlign : "center"
        }
          # не мигать если только что нашли блок
          if block_height_hash[@state.height] or block_height_hash[@state.height - 1]
            count = 0
            real_block_time_sum = 0
            hash_count_sum = 0
            prev_block = null
            for k, block of block_height_hash
              if prev_block
                real_block_time = block.timestamp - prev_block.timestamp
                # net_hashrate += diff_to_avg_hash_count(block.diff)/real_block_time
                hash_count_sum += diff_to_avg_hash_count(block.diff)
                real_block_time_sum += real_block_time
                count++
              prev_block = block
            net_hashrate = hash_count_sum/real_block_time_sum
            span net_hashrate.to_format_float_string 0
          else
            Spinner {}
      Last_block_list {}
