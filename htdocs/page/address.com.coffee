module.exports =
  state :
    address : null
    height  : null
  
  tx_list : []
  tx_load_limit : 20
  
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
    @tx_list = []
    return if !@props.address?
    await address_get props.address, defer(err, address); throw err if err
    
    # BUG не сортировано
    @tx_list.append address.txs
    @tx_list.append address.deposits
    @set_state {address}
  
  props_change : (new_props)->
    @set_state address : null
    @refresh new_props
  
  render : ()->
    Page_wrap {value:"address"}
      div
        if !@state.address # возможно не самое лучшее решение
          Spinner {}
        else
          {address} = @state
          table {
            class: "table"
            style:
              fontSize  : 16
              marginBottom : 10
          }
            td_style =
              width     : 400
              fontFamily: "monospace"
            tbody
              tr
                th "Address"
                td {style:td_style}, @props.address
              tr
                th "Balance"
                td {style:td_style}, winston_to_ar_format address.balance
              tr
                th "Tx count"
                td {style:td_style}, if @tx_list.length == @tx_load_limit then "#{@tx_load_limit}+" else @tx_list.length
          Tx_list {
            tx_list : @tx_list
            tx_limit: @tx_limit
            address : @props.address
            show_height : true
            show_confirmations : true
            height  : @state.height
          }
