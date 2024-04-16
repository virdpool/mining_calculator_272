module.exports =
  state :
    tx    : null
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
    return if !@props.txid?
    await tx_get props.txid, defer(err, tx); throw err if err
    
    @set_state {tx}
  
  props_change : (new_props)->
    @set_state tx : null
    @refresh new_props
  
  render : ()->
    Page_wrap {value:"tx"}
      div
        if !@state.tx # возможно не самое лучшее решение
          Spinner {}
        else
          {tx} = @state
          table {
            class: "table"
            style:
              fontSize  : 16
              
          }
            td_style =
              width     : 300
              fontFamily: "monospace"
            tbody
              tr
                th "Hash"
                td {style:td_style}, tx.id
              tr {
                style:
                  cursor : "pointer"
                on_click : ()=>
                  route_go "address/#{tx.owner_address}"
              }
                th "From"
                td Link_address value:tx.owner_address
              tr {
                style:
                  cursor : "pointer"
                on_click : ()=>
                  route_go "address/#{tx.target}"
              }
                th "To"
                td Link_address value: tx.target
              tr
                th "Value"
                td {style:td_style}, winston_to_ar_format tx.quantity
              tr
                th "Fee"
                td {style:td_style}, winston_to_ar_format tx.reward
              tr
                th "Size"
                td {style:td_style}, tx.data_size
              # TODO block, confirmations
