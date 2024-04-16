module.exports =
  render : ()->
    div
      map_hash =
        dashboard   : "Dashboard" # трюк работает т.к. redirrect
        # address_list: "Addresses"
        peer_list   : "Peers"
        calculator  : "Calculator"
        # calculator_272: "Calculator 2.7.2 WIP"
        pool        : "Pool"
      Tab_bar {
        value : @props.value
        hash  : map_hash
        on_change : (t)=>
          t = "" if t == "dashboard"
          if t == "pool"
            location.href = "https://ar.virdpool.com/"
            return
          route_go t
        btn_style :
          fontSize  : 20
        style:
          marginBottom : 10
      }
      @props.children
