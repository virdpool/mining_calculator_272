module.exports =
  mount : ()->
    txid_list = @props.tx_list
    tx_limit  = @props.tx_limit ? 20
    txid_list_sort = ()->
      txid_list.sort (a,b)->
        a_val = tx_hash[a]?.status.block_height ? 0
        b_val = tx_hash[b]?.status.block_height ? 0
        -(a_val - b_val)
    
    if txid_list.length
      last_update_ts = Date.now()
      
      # fast cache
      limit_txid_list = txid_list.slice(0, tx_limit)
      await tx_get_bulk limit_txid_list, defer(err, txid_hash); throw err if err
      if h_count txid_hash
        @force_update()
      
      for txid,idx in txid_list
        break if idx >= tx_limit
        continue if tx_hash[txid]
        await tx_get txid, defer(err, tx); throw err if err
        if Date.now() - last_update_ts > 300
          last_update_ts = Date.now()
          txid_list_sort()
          @force_update()
      
      txid_list_sort()
      @force_update()
      # TODO remove
      if txid_list.length < tx_limit
        @props.on_last_tx_load? tx_hash[txid_list.last()]
  
  render : ()->
    show_height       = @props.show_height        ? false
    show_confirmations= @props.show_confirmations ? false
    
    show_confirmations= false if !@props.height?
    
    tx_limit = @props.tx_limit ? 20 # TODO DE-copypaste
    wide = load_lsg @, "wide"
    Group {
      label_fn : ()=>
        div
          span {
            style :
              fontSize  : 16
              fontWeight: "bold"
          }, "Transactions"
          Checkbox bind2lsg @, "wide", {
            value_preprocess : (t)->
              t = false if !t?
              return t
            label : "wide"
            parent_style :
              fontWeight : "normal"
          }
    }
      table {
        class: "table table_monospace"
        style:
          width   : if wide then 1700 else 1000
      }
        tbody
          tr
            th "#"
            th "Hash"
            th "From"
            th "To"
            th "Value"
            th "Fee"
            if show_height
              th "Height"
            if show_confirmations
              th
                Tooltip {
                  tooltip_render : ()=>
                    div {
                      style :
                        background  : "#fff"
                        padding     : 5
                        borderRadius: 5
                        border      : "1px solid #000"
                        fontFamily  : "monospace"
                        whiteSpace  : "nowrap"
                    }, "Confirmations"
                }
                  span "Conf."
            # th "Date"
            # th "Method"
          for txid, idx in @props.tx_list
            break if idx >= tx_limit
            do (txid,idx)=>
              tr {key:txid}
                td_number_click_props = {
                  style:
                    textAlign : "right"
                    cursor    : "pointer"
                  on_click : ()=>
                    route_go "tx/#{txid}"
                }
                td td_number_click_props, idx+1
                td Link_tx {wide, value: txid}
                if !tx = tx_hash[txid]
                  td {
                    colSpan : 4
                    style:
                      textAlign: "center"
                  }
                    Spinner {}
                else
                  td Link_address {wide, value: tx.owner_address}
                  td Link_address {wide, value: tx.target}
                  sign = if tx.owner_address == @props.address then -1 else 1
                  td td_number_click_props, Money_ar value : sign*tx.quantity
                  td td_number_click_props, Money_ar value : -tx.reward
                  if show_height
                    td {
                      style:
                        textAlign : "right"
                        cursor    : "pointer"
                      on_click : ()=>
                        route_go "block/#{tx.status.block_height}"
                    }
                      tx.status.block_height
                  if show_confirmations
                    td {
                      style:
                        textAlign : "right"
                        cursor    : "pointer"
                      on_click : ()=>
                        route_go "block/#{tx.status.block_height}"
                    }
                      @props.height - tx.status.block_height
                  # td
                    # if tx.timestamp?
                      # date = dayjs(tx.timestamp*1000)
                      # "#{date.format('DD.MM.YYYY HH:mm')} (#{date.fromNow()})"
