module.exports =
  state :
    block : null
    height: null
  
  on_unmount_list : []
  is_mounted : true
  mount : ()->
    @on_unmount_list = []
    simple_sub_endpoint @, "height", (res)=>
      @set_state {
        height : res.height
      }
    @refresh()
  
  tx_limit : 20
  unmount : ()->
    @is_mounted = false
    for fn in @on_unmount_list
      try
        fn()
      catch err
        perr err
    return
  
  refresh : (props = @props)->
    if props.height?
      await block_get_by_height props.height, defer(err, block); throw err if err
    else
      await block_get_by_hash props.hash, defer(err, block); throw err if err
    
    @set_state {block}
    txid_list = block.txs
  
  props_change : (new_props)->
    @set_state block : null
    @refresh new_props
  
  render : ()->
    Page_wrap {value:"block"}
      Button {
        label   : "Prev"
        disabled: !@state.block or @state.block.height == 0
        on_click: ()=>
          route_go "block/#{@state.block.height-1}"
      }
      Button {
        label   : "Next"
        disabled: !@state.height? or !@state.block or @state.block.height == @state.height
        on_click: ()=>
          route_go "block/#{@state.block.height+1}"
      }
      div
        if !@state.block # возможно не самое лучшее решение
          Spinner {}
        else
          {block} = @state
          table {
            class: "table"
            style:
              fontSize  : 16
              marginBottom : 10
          }
            td_style =
              width     : 600
              fontFamily: "monospace"
            tbody
              tr
                th {style:width:100}, "Height"
                td {style:td_style}, block.height.to_format_int_string()
              tr
                th "Hash"
                # td {style:td_style}, block.indep_hash.cut_mid 32
                td {style:td_style}, block.indep_hash
              tr
                th "Nonce"
                td {style:td_style}, block.nonce
              tr
                th "Date"
                td {style:td_style}
                  date = dayjs(block.timestamp*1000)
                  "#{date.format('DD.MM.YYYY HH:mm')} (#{date.fromNow()})"
              tr
                th "Transactions"
                td {style:td_style}, block.txs.length
              tr
                th "Block size"
                td {style:td_style}, block.block_size.to_format_int_string()
              tr
                th "Weave size"
                td {style:td_style}, block.weave_size.to_format_int_string() # TODO kb, gb, tb + tooltip
              tr
                th "Miner"
                td Link_address wide: true, value: block.reward_addr
              tr
                th "Reward"
                td Money_ar value: block.reward
              tr
                th "Confirmations"
                td {style:td_style}
                  if !@state.height?
                    Spinner {}
                  else
                    @state.height - block.height
              # TODO mined_time (нужен prev block)
          if @state.block.txs.length
            Tx_list {
              tx_list : @state.block.txs
              tx_limit: @tx_limit
            }
      