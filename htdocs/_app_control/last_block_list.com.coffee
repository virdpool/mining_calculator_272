module.exports =
  state :
    last_block_list : null
  
  on_unmount_list : []
  is_mounted : true
  mount : ()->
    @on_unmount_list = []
    simple_sub_endpoint @, "last_block_list", (res)=>
      # puts "last_block_list", res
      if res.last_block_list
        for block in res.last_block_list
          block_height_hash[block.height] = block
      
      @set_state {
        last_block_list : res.last_block_list.slice(0, 50)
      }
    # timestamp update
    do ()=>
      while @is_mounted
        await setTimeout defer(), 10000
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
    wide = load_lsg @, "wide"
    
    Group {
      label_fn : ()=>
        div
          span {
            style :
              fontSize  : 16
              fontWeight: "bold"
          }, "Blocks"
          Checkbox bind2lsg @, "wide", {
            value_preprocess : (t)->
              t = false if !t?
              return t
            label : "wide"
            parent_style :
              fontWeight : "normal"
          }
      style:
        width : if wide then 1700 else 1000
    }
      table {
        class : "table table_monospace"
        style :
          width     : "100%"
          textAlign : "center"
      }
        tbody
          tr
            th "Height"
            th "Hash"
            th {style:width : 180}, "Time"
            th "Tx count"
            th "Size"
            th "Miner"
            th "Reward"
            th "Diff"
          if @state.last_block_list
            for block,idx in @state.last_block_list
              prev_block = @state.last_block_list[idx+1]
              do (block,prev_block)=>
                prop_click_block = {
                  style :
                    cursor    : "pointer"
                  on_click : (e)=>
                    e.stopPropagation()
                    route_go "block/#{block.height}"
                }
                tr
                  td prop_click_block, block.height
                  td prop_click_block, Link_block {wide, value:block.indep_hash}
                  td prop_click_block, Time value : block.timestamp
                  td prop_click_block, block.txs_count
                  td prop_click_block, block.block_size
                  td Link_address {wide, value:block.reward_addr}
                  td prop_click_block, Money_ar value : block.reward
                  td prop_click_block, Diff {value : block.diff, block, prev_block}
