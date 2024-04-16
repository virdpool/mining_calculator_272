module.exports =
  state :
    address_list : null
  
  on_unmount_list : []
  is_mounted : true
  mount : ()->
    @on_unmount_list = []
    simple_sub_endpoint @, "address_list", (res)=>
      @set_state {
        address_list : res.address_list
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
    view_limit = 50
    Page_wrap {value:"address_list"}
      "TODO address list"
      if !@state.address_list
        Spinner {}
      else
        # TODO Group
        table {
          class : "table table_monospace"
        }
          tbody
            tr
              th "Hash"
              th "Balance"
            for address, idx in @state.address_list
              break if idx > view_limit
              tr
                td Link_address value : address.address
                td {
                  style:
                    textAlign : "right"
                }, Money_ar value : address.balance
          
      