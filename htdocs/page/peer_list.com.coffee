module.exports =
  state :
    peer_list   : []
    ping_measure_in_progress : false
    check_chunk : true
    need_stop   : false
  
  on_unmount_list : []
  is_mounted : true
  mount : ()->
    @on_unmount_list = []
    simple_sub_endpoint @, "peer_list", (res)=>
      peer_list = @state.peer_list
      ip_hash = {}
      for peer in peer_list
        ip_hash[peer.host] = true
      
      for peer in res.peer_list
        continue if ip_hash[peer]
        peer_list.push {
          host : peer
          ping : null
        }
      @set_state {
        peer_list
      }
  
  unmount : ()->
    @is_mounted = false
    for fn in @on_unmount_list
      try
        fn()
      catch err
        perr err
    return
  
  measure_ping : ()->
    @set_state ping_measure_in_progress : true
    
    # TODO parallel check
    # TODO shuffle
    
    peer_list = @state.peer_list.clone()
    for peer in peer_list
      peer.ping = null
      peer.chunk_ok = null
    
    for peer in peer_list
      break if @state.need_stop
      req_opt =
        url     : "http://#{peer.host}"
        timeout : 3000
      
      peer.ping = "in progress"
      start_ts = Date.now()
      await fetch_timeout req_opt, defer(err);
      # TODO check joined
      if err
        peer.ping = Infinity 
      else
        peer.ping = Date.now() - start_ts
      
      @force_update()
      
      if @state.check_chunk
        # TODO randomize chunk
        req_opt =
          url     : "http://#{peer.host}/chunk/1"
          timeout : 10000
        peer.chunk_ok = "in progress"
        await fetch_timeout req_opt, defer(err, res);
        if err
          peer.chunk_ok = false
        else
          try
            JSON.parse res
            peer.chunk_ok = true
          catch err
            peer.chunk_ok = false
      
      if @state.peer_list
        @state.peer_list.sort (a,b)->
          a_val = a.ping ? Infinity
          b_val = b.ping ? Infinity
          a_val - b_val
    # TODO sort peer_list by ping
    
    @set_state
      ping_measure_in_progress : false
      need_stop : false
  
  render : ()->
    peer_list = [] # filtered by chunk_ok
    if @state.peer_list
      {peer_list} = @state
      if @state.check_chunk
        peer_list = peer_list.filter (t)->t.chunk_ok
    Page_wrap {value:"peer_list"}
      table {
        class: "table"
        style:
          marginBottom : 10
          width : "100%"
      }
        
        # TODO clipboard
        tbody
          tr
            td {colSpan:2}
              b "WARNING"
              div "It's not safe to specify arbitrary peers on startup. Please, consider joining using only the nodes from the mining guide and your own addresses (if you already have nodes running), and any other addresses you trust, if any."
          if location.protocol != "http:"
            tr
              td {colSpan:2}
                b "WARNING"
                div " this page will not work with https"
                Link href : "http://explorer.ar.virdpool.com/#/peer_list"
          tr
            td {colSpan : 2}
              if !@state.ping_measure_in_progress
                Button {
                  label : "Measure ping"
                  # disabled : @state.ping_measure_in_progress
                  style :
                    width : "100%"
                  on_click : ()=>
                    @measure_ping()
                }
              else
                Button {
                  label : "Stop"
                  disabled : @state.need_stop
                  style :
                    width : "100%"
                  on_click : ()=>
                    @set_state need_stop : true
                }
          tr
            th {style:width:230},"Check chunk"
            td
              Checkbox bind2 @, "check_chunk"
          for ping_level in [200, 500, 1000]
            tr
              th "connect str ping < #{ping_level}"
              td
                if @state.peer_list?
                  Textarea {
                    readonly : true
                    rows : 5
                    style :
                      width : "100%"
                      boxSizing : "border-box"
                    value : peer_list
                      .filter((t)=>(t.ping ? Infinity) < ping_level)
                      .map((t)->"peer #{t.host}")
                      .join(" ")
                  }
          tr
            th "connect str all"
            td
              if @state.peer_list?
                Textarea {
                  readonly : true
                  rows : 5
                  style :
                    width : "100%"
                    boxSizing : "border-box"
                  value : peer_list.map((t)->"peer #{t.host}").join(" ")
                }
      
      table {
        class: "table table_monospace"
        style:
          textAlign : "center"
      }
        tbody
          tr
            th "live"
            th "IP"
            th "ping"
            if @state.check_chunk
              th "chunk ok"
          if !@state.peer_list
            tr
              td {colSpan:3}
                Spinner {}
          else
            for peer in @state.peer_list
              {ping} = peer
              tr
                td
                  if !ping?
                    "?"
                  else if ping == "in progress"
                    Spinner {}
                  else if isFinite ping
                    "+"
                  else
                    ""
                td peer.host
                td
                  if !ping?
                    "?"
                  else if ping == "in progress"
                    Spinner {}
                  else
                    return ping
                if @state.check_chunk
                  td
                    if !peer.chunk_ok?
                      "?"
                    else if peer.chunk_ok == "in progress"
                      Spinner {}
                    else if peer.chunk_ok
                      "+"
                    else
                      ""
