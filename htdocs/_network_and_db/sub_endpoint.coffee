# еще немного упрощает жизнь
window.simple_sub_endpoint = (com, switch_key, on_refresh)->
  loc_opt = {
    sub   : switch :  "#{switch_key}_sub"
    unsub : switch : "#{switch_key}_unsub"
    switch: "#{switch_key}_stream"
  }
  com.on_unmount_list.push ws_back.sub loc_opt, (data)=>
    if com.is_mounted
      if data.error
        perr switch_key, data.error
      else
        on_refresh data.res
    return
