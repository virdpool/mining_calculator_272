storage_type_to_gb_bandwidth_hash =
  nvme_pcie5  : 15.75
  nvme_pcie4  : 7.88
  nvme_pcie3  : 3.94
  nvme_pcie2  : 2
  
  nvme_pcie4_typ  : 2
  nvme_pcie3_typ  : 1
  sata3_ssd   : 0.550
  sata2_ssd   : 0.550/2
  hdd         : 0.150

storage_type_to_iops_hash =
  nvme_pcie5  : 2e6
  nvme_pcie4  : 1e6
  nvme_pcie3  : 0.5e6
  nvme_pcie2  : 0.1e5
  sata3_ssd   : 0.1e5
  sata2_ssd   : 0.1e5
  hdd         : 200
obj_set storage_type_to_iops_hash, {
  nvme_pcie4_typ : storage_type_to_iops_hash.nvme_pcie4
  nvme_pcie3_typ : storage_type_to_iops_hash.nvme_pcie3
}

gb_mult = 1024*1024*1024
storage_read_efficiency = 0.86 # best I ever seen

raid_type_to_efficiency_hash =
  "raid0"   : 0.8
  "manual"  : 1

module.exports =
  state :
    # hashrate_mode : "spora" # spora | randomx | cpu
    hashrate_mode : "spora"
    # USER
    raid_type        : "raid0" # "raid0" | "manual"
    raid_effificency : 0.8
    storage_type  : "nvme_pcie3_typ" # nvme_pcie4 | nvme_pcie3 | nvme_pcie2 | nvme_pcie4_typ | nvme_pcie3_typ | sata3_ssd | sata2_ssd | hdd
    storage_count : 1
    
    cpu_model               : "AMD THREADRIPPER 3990X"
    cpu_count               : 1
    
    randomx_hashrate        : 100000
    
    spora_hashrate          : 10000
    spora_hashrate_cpu      : 10000
    spora_hashrate_iops     : 1000000
    spora_hashrate_storage  : Infinity # TODO fixme; means bandwidth limiter
    storage_size            : 8*(1024*1024*1024*1024) # based on your storage size
    
    # AUTO
    height      : null
    
    # TODO AUTO
    net_hashrate            : 70e6
    net_hashrate_v1         : 70e6
    hash_count_per_block_avg: 120*70e6
    weave_size              : 60337091813622 # https://arweave.net/block/current
    # max_available_data_size : 50472815488832 # https://arweave.net/metrics
    max_available_data_size : 75293544803310 # http://gateway-2.arweave.net:1984/metrics
    
    exchange_rate : 50
    block_reward  : 0.73
    
    exchange_rate_is_loading : true
    exchange_rate_load_error : false
    
    max_storage_is_loading_start : false
    max_storage_is_loading : true
    max_storage_load_error : false
    
    weave_size_is_loading : true
    weave_size_load_error : false
    
    real_block_time : 120
    pool_fee_enabled: true
    pool_fee        : 0.05
    arweave_node_penalty_enabled : true
    arweave_node_penalty : 0.7
  
  on_unmount_list : []
  is_mounted : true
  mount : ()->
    @on_unmount_list = []
    simple_sub_endpoint @, "last_block_list", (res)=>
      if res.last_block_list
        for block in res.last_block_list
          block_height_hash[block.height] = block
        
        block_reward_sum = 0
        block_reward_count = 0
        for block in res.last_block_list
          continue if !block.reward
          block_reward_count++
          block_reward_sum += +block.reward
        @set_state {
          block_reward : winston_to_ar block_reward_sum/block_reward_count
          block_reward_count
        }
        call_later ()=>@calculate_spora_hashrate()
      
      
      @block_data_refresh()
      return
    
    simple_sub_endpoint @, "height", (res)=>
      @set_state {
        height : res.height
      }
      @block_data_refresh res.height
      call_later ()=>@calculate_spora_hashrate()
    
    @update_metrics()
    
    setTimeout ()=>
      return if !@state.weave_size_is_loading and !@state.max_storage_load_error
      puts "backup weave_size request"
      fetch("https://arweave.net/block/current").cb (err,res)=>
        return if err
        res.text().cb (err, res)=>
          return if err
          try
            data = JSON.parse res
          catch err
            perr "BAD JSON https://arweave.net/block/current #{res}"
            return
          
          value = +data.weave_size
          if isFinite value
            @set_state
              weave_size : value
              weave_size_is_loading : false
            call_later ()=>@calculate_spora_hashrate()
          else
            perr data
            perr "bad value weave_size #{data.weave_size}"
    , 3000
    
    @exchange_rate_refresh()
    
    {query_hash} = @props
    
    # ###################################################################################################
    #    misc
    # ###################################################################################################
    if query_hash.hashrate_mode
      if query_hash.hashrate_mode in ["spora", "randomx", "cpu"]
        @set_state hashrate_mode : query_hash.hashrate_mode
    
    cpu_count = 1
    if query_hash.cpu_count
      if isFinite value = +query_hash.cpu_count
        @set_state cpu_count : value
        cpu_count = value
    
    if query_hash.cpu_model
      for v in cpu_model_list
        if v.value == query_hash.cpu_model
          @set_state
            cpu_model : v.value
            randomx_hashrate : model_to_hashrate[v.value] * cpu_count
    
    # ###################################################################################################
    #    hashrate
    # ###################################################################################################
    if query_hash.spora_hashrate
      if isFinite value = +query_hash.spora_hashrate
        @set_state spora_hashrate : value
    
    if query_hash.randomx_hashrate
      if isFinite value = +query_hash.randomx_hashrate
        @set_state randomx_hashrate : value
    
    # ###################################################################################################
    #    storage
    # ###################################################################################################
    if query_hash.storage_count
      if isFinite value = +query_hash.storage_count
        @set_state storage_count : value
    
    if query_hash.storage_size
      if isFinite value = +query_hash.storage_size
        @set_state storage_size : value
    
    if query_hash.storage_type
      if query_hash.storage_type in ["nvme_pcie4", "nvme_pcie3", "nvme_pcie2", "nvme_pcie4_typ", "nvme_pcie3_typ", "sata3_ssd", "sata2_ssd", "hdd"]
        @set_state storage_type : query_hash.storage_type
    
    if query_hash.raid_type
      if query_hash.raid_type in ["raid0", "manual"]
        @set_state raid_type : query_hash.raid_type
    
    if query_hash.arweave_node_penalty_enabled?
      @set_state arweave_node_penalty_enabled : !!+query_hash.arweave_node_penalty_enabled
    
    call_later ()=>@calculate_spora_hashrate()
  
  unmount : ()->
    @is_mounted = false
    for fn in @on_unmount_list
      try
        fn()
      catch err
        perr err
    return
  
  update_metrics : ()->
    do ()=>
      @set_state
        max_storage_is_loading_start : true
      old_max_available_data_size = 0
      while old_max_available_data_size != @state.max_available_data_size
        old_max_available_data_size = @state.max_available_data_size
        for i in [0 ... 4]
          puts "_update_metrics", @state.max_available_data_size//1024**3
          @_update_metrics() # cb?
          await setTimeout defer(), 1000
      @set_state
        max_storage_is_loading_start : false
      return
    return
  
  _update_metrics : ()->
    fetch("https://arweave.net/metrics").cb (err,res)=>
      if err
        @set_state
          max_storage_is_loading : false
          max_storage_load_error : true
        return
      res.text().cb (err, res)=>
        if err
          @set_state
            max_storage_is_loading : false
            max_storage_load_error : true
          return
        list = res.split("\n").filter (t)->
          return false if t[0] == "#"
          /v2_index_data_size /.test t
        
        if list.length
          value = +list.last().split(" ")[1]
          if isFinite value
            # puts "value", value, list
            # FUCK failover
            # arweave.net может вернуть ояебу значение
            value = Math.max value, @state.max_available_data_size
            @set_state
              max_available_data_size: value
              max_storage_is_loading : false
              max_storage_load_error : false
            call_later ()=>@calculate_spora_hashrate()
          else
            @set_state
              max_storage_is_loading : false
              max_storage_load_error : true
            perr "bad value v2_index_data_size #{value}"
        else
          @set_state
            max_storage_is_loading : false
            max_storage_load_error : true
          perr "missing v2_index_data_size"
  
  block_data_refresh : (height = @state.height)->
    for i in [0 ... 100]
      break if block = block_height_hash[height]
      height--
    if block
      net_hashrate_v1 = 0
      count = 0
      prev_block = null
      real_block_time_sum = 0
      hash_count_sum = 0
      for k, block of block_height_hash
        if prev_block
          real_block_time = block.timestamp - prev_block.timestamp
          
          hash_count = diff_to_avg_hash_count block.diff
          hash_count_sum  += hash_count
          real_block_time_sum += real_block_time
          net_hashrate_v1 += hash_count/block_time
          count++
        prev_block = block
      
      net_hashrate = hash_count_sum/real_block_time_sum
      net_hashrate_v1 /= count
      @set_state {
        net_hashrate
        net_hashrate_v1
        # hash_count_per_block_avg: net_hashrate/(real_block_time_sum / count)
        hash_count_per_block_avg: hash_count_sum / count
        real_block_time       : real_block_time_sum/count
        weave_size            : block.weave_size
        weave_size_is_loading : false
        weave_size_load_error : false
      }
    @force_update()
  
  exchange_rate_refresh : ()->
    # NOTE we assume 1 USDT == 1 USD
    # fetch("https://api.binance.com/api/v3/avgPrice?symbol=ARUSDT").cb (err,res)=>
    fetch("https://api.binance.com/api/v3/ticker/24hr?symbol=ARUSDT").cb (err,res)=>
      if err
        @set_state
          exchange_rate_is_loading : false
          exchange_rate_load_error : true
        return
      res.text().cb (err, res)=>
        if err
          @set_state
            exchange_rate_is_loading : false
            exchange_rate_load_error : true
          return
        try
          data = JSON.parse res
        catch err
          @set_state
            exchange_rate_is_loading : false
            exchange_rate_load_error : true
          perr "BAD JSON binance #{res}"
          return
        
        # value = +data.price
        value = +data.weightedAvgPrice
        if isFinite value
          @set_state
            exchange_rate : +value.toFixed 2
            exchange_rate_is_loading : false
            exchange_rate_load_error : false
        else
          @set_state
            exchange_rate_is_loading : false
            exchange_rate_load_error : true
          perr data
          # perr "bad value price #{data.price}"
          perr "bad value price #{data.weightedAvgPrice}"
  
  calculate_spora_hashrate : ()->
    storage_size      = Math.min @state.storage_count*@state.storage_size, @state.max_available_data_size
    effective_storage_size = storage_size
    if @state.arweave_node_penalty_enabled
      effective_storage_size *= @state.arweave_node_penalty
    spora_hashrate_cpu= Math.round @state.randomx_hashrate/(1 + @state.weave_size/effective_storage_size)
    
    gb_to_hs_mult = 1024 * 4
    switch @state.raid_type
      when "raid0"
        spora_hashrate_storage  = @state.storage_count * storage_read_efficiency * storage_type_to_gb_bandwidth_hash[@state.storage_type] * gb_to_hs_mult
        spora_hashrate_iops     = storage_type_to_iops_hash[@state.storage_type]
        if @state.storage_count > 1
          spora_hashrate_storage *= @state.raid_effificency
      
      # when "manual"
      else 
        spora_hashrate_storage  = @state.storage_count * storage_read_efficiency * storage_type_to_gb_bandwidth_hash[@state.storage_type] * gb_to_hs_mult
        spora_hashrate_iops     = @state.storage_count * storage_type_to_iops_hash[@state.storage_type]
      
    
    if @state.hashrate_mode in ["randomx", "cpu"]
      @set_state {
        spora_hashrate_storage  : Math.round spora_hashrate_storage
        spora_hashrate_cpu      : Math.round spora_hashrate_cpu
        spora_hashrate_iops     : Math.round spora_hashrate_iops
        spora_hashrate          : Math.round Math.min spora_hashrate_cpu, spora_hashrate_storage, spora_hashrate_iops
      }
    # set query
    switch @state.hashrate_mode
      when "spora"
        # puts "HERE"+[
          # "hashrate_mode=#{@state.hashrate_mode}"
          # "spora_hashrate=#{@state.spora_hashrate}"
        # ].join "&"
        history.replaceState {}, "Arweave block explorer", "#/calculator/"+[
          "hashrate_mode=#{@state.hashrate_mode}"
          "spora_hashrate=#{@state.spora_hashrate}"
        ].join "&"
      when "randomx"
        history.replaceState {}, "Arweave block explorer", "#/calculator/"+[
          "hashrate_mode=#{@state.hashrate_mode}"
          "randomx_hashrate=#{@state.randomx_hashrate}"
          "storage_count=#{@state.storage_count}"
          "storage_type=#{@state.storage_type}"
          "storage_size=#{@state.storage_size}"
          "raid_type=#{@state.raid_type}"
          "arweave_node_penalty_enabled=#{+@state.arweave_node_penalty_enabled}"
        ].join "&"
      when "cpu"
        history.replaceState {}, "Arweave block explorer", "#/calculator/"+[
          "hashrate_mode=#{@state.hashrate_mode}"
          "cpu_model=#{@state.cpu_model}"
          "cpu_count=#{@state.cpu_count}"
          "storage_count=#{@state.storage_count}"
          "storage_type=#{@state.storage_type}"
          "storage_size=#{@state.storage_size}"
          "raid_type=#{@state.raid_type}"
          "arweave_node_penalty_enabled=#{+@state.arweave_node_penalty_enabled}"
        ].join "&"
  
  render : ()->
    Page_wrap {value:"calculator"}
      h3 "The most advanced Arweave profit and hashrate calculator"
      table {class : "table"}
        tbody
          # tr
          #   th {
          #     colSpan : 5
          #   }
          #     Tooltip {
          #       mount_point_y : "bottom"
          #       position_y    : "top"
          #       tooltip_render : ()=>
          #         div {
          #           style :
          #             background  : "#fff"
          #             padding     : 5
          #             borderRadius: 5
          #             border      : "1px solid #000"
          #             fontFamily  : "monospace"
          #             fontWeight  : "normal"
          #             whiteSpace  : "nowrap"
          #             textAlign   : "left"
          #         }
          #           div "* Changed SPoRA net hashrate formula to more correct one (now != chronobot)"
          #           div "* Reworked storage bandwidth constants"
          #           div "* Fixed block reward"
          #           div "* Pool fee option added"
          #     }
          #       div {style:cursor:"pointer"}
          #         span "6 oct "
          #         span {style:color:"#ff0000"}, "Methodics was changed."
          #         span " Now results should be more accurate (hover for changelog)"
          tr
            th {
              style:
                width : 400
            }, ""
            td {
              colSpan : 4
            }
              list = [
                {
                  mode : "spora"
                  title: "I know my SPoRA hashrate"
                }
                {
                  mode : "randomx"
                  title: "I know my randomx hashrate (done benchmark with OPTIMIZED params)"
                }
                {
                  mode : "cpu"
                  title: "I know only my CPU model (didn't launch benchmark)"
                }
              ]
              for v in list
                do (v)=>
                  on_click = ()=>
                    @set_state hashrate_mode : v.mode
                    if v.mode == "cpu"
                      cpu_model = "AMD THREADRIPPER 3990X"
                      cpu_count = 1
                      @set_state {
                        cpu_model
                        cpu_count
                        randomx_hashrate : model_to_hashrate[cpu_model] * cpu_count
                      }
                    # for refresh URL
                    call_later ()=>@calculate_spora_hashrate()
                  div
                    input {
                      id   : v.mode
                      type : "radio"
                      checked : @state.hashrate_mode == v.mode
                      style :
                        cursor : "pointer"
                      on_click
                    }
                    label {
                      for : v.mode
                      style :
                        cursor : "pointer"
                      on_click
                    }, v.title
          tr
            th {colSpan: 5}, "CPU"
          if @state.hashrate_mode == "cpu"
            tr
              th "CPU model"
              td {colSpan : 4}
                Select {
                  list : cpu_model_list
                  value : @state.cpu_model
                  style :
                    fontFamily : "monospace"
                  on_change : (cpu_model)=>
                    {cpu_count} = @state
                    cpu_count = Math.min cpu_count, model_to_max_cpu[cpu_model]
                    @set_state {
                      cpu_model
                      cpu_count
                      randomx_hashrate : model_to_hashrate[cpu_model] * cpu_count
                    }
                    call_later ()=>@calculate_spora_hashrate()
                }
                span " "
                a {
                  href : "https://monerobenchmarks.info/index.php"
                  target : "_blank"
                }, "source"
                div
                  span {style:color:"#ff0000"}, "WARNING"
                  span " this is only estimated hashrate = 0.7*monero-randomx"
                div
                  span "* marked had hashrate deviation (inaccurate measure)"
            tr
              th "CPU count (on ONE motherboard)"
              td {colSpan : 4}
                Number_input {
                  value : @state.cpu_count
                  disabled : model_to_max_cpu[@state.cpu_model] == 1
                  on_change : (cpu_count)=>
                    cpu_count = Math.round cpu_count
                    cpu_count = Math.max 1, cpu_count
                    cpu_count = Math.min model_to_max_cpu[@state.cpu_model], cpu_count
                    @set_state {
                      cpu_count
                      randomx_hashrate : model_to_hashrate[@state.cpu_model] * cpu_count
                    }
                    call_later ()=>@calculate_spora_hashrate()
                }
                span " (max #{model_to_max_cpu[@state.cpu_model]})"
                if @state.cpu_count > 1
                  div
                    span {style:color:"#ff0000"}, "WARNING"
                    span " you should benchmark until buy such setup."
                    div "Arweave is not optimized for multiCPU setup"
          if @state.hashrate_mode in ["randomx", "cpu"]
            tr
              th "Randomx hashrate"
              td {
                colSpan : 4
              }
                Number_input bind2 @, "randomx_hashrate", {
                  disabled : @state.hashrate_mode == "cpu"
                  on_change : ()=>
                    call_later ()=> @calculate_spora_hashrate()
                }
                span " h/s"
          if @state.hashrate_mode in ["randomx", "cpu"]
            tr
              th {colSpan: 5}, "Storage"
            tr
              th "Arweave node chunk_storage penalty"
              td {
                colSpan : 4
              }
                Checkbox {
                  value : @state.arweave_node_penalty_enabled
                  on_change : (arweave_node_penalty_enabled)=>
                    @set_state {arweave_node_penalty_enabled}
                    call_later ()=>@calculate_spora_hashrate()
                }
                span " chunk_storage does not use chunks != 256k for mining (efficiency #{(@state.arweave_node_penalty*100).toFixed(0)}%)"
                # div "you should enable search_in_rocksdb_when_mining and buy extra fast storage for rocksdb to reduce this penalty"
                div "Note that in 2.5 enable search_in_rocksdb_when_mining will not add you any gains after all data will be repacked (2-3 month estimate). Rocksdb data is not repacked at all"
            tr
              th "Weave size"
              td {
                colSpan : 4
              }
                span "#{(@state.weave_size / gb_mult).toFixed 2} GB"
                if @state.weave_size_is_loading
                  Spinner {}
                else if @state.weave_size_load_error
                  span "load error"
            tr
              th "Storage size (1 device)"
              td {
                colSpan : 3
              }
                Number_input {
                  value : Math.round @state.storage_size / gb_mult
                  on_change : (value)=>
                    value = Math.max 0, value
                    @set_state storage_size : value * gb_mult
                    call_later ()=>@calculate_spora_hashrate()
                }
                max_available_data_size = @state.max_available_data_size / gb_mult
                span " GB for 1 device"
                div
                  span "(max #{Math.round max_available_data_size} GB) "
                  Button {
                    label   : "refresh"
                    on_click: ()=>@_update_metrics()
                  }
                  span " "
                  Tooltip {
                    mount_point_y : "bottom"
                    position_y    : "top"
                    tooltip_render : ()=>
                      div {
                        style :
                          background  : "#fff"
                          padding     : 5
                          borderRadius: 5
                          border      : "1px solid #000"
                          fontFamily  : "monospace"
                          fontWeight  : "normal"
                          whiteSpace  : "nowrap"
                          textAlign   : "left"
                      }
                        div
                          span "Not all data chunks are publicly available"
                        div
                          span "Only 256k chunks are mineable by arweave node"
                        div
                          span "Learn more about "
                          a {
                            href  : "https://twitter.com/samecwilliams/status/1374062282817290247"
                            target: "_blank"
                          }, "sacrifice miners"
                        div
                          span "Note. This data can be inaccurate because arweave.net node is load balanced"
                        div
                          span "Also network grows really fast and there is some sync problems"
                        div
                          span "Hit refresh if you see some strange number"
                  }
                    div {
                      style:
                        cursor    : "pointer"
                        fontWeight: "bold"
                    }, "(?)"
                  if @state.max_storage_is_loading or @state.max_storage_is_loading_start
                    Spinner {}
                  else if @state.max_storage_load_error
                    span "load error"
                
              td
                storage_size      = Math.min @state.storage_count*@state.storage_size, @state.max_available_data_size
                storage_ratio = storage_size / @state.max_available_data_size
                div "#{(100*storage_ratio).toFixed 2}% efficiency"
                total_storaege = Math.round @state.storage_count*@state.storage_size / gb_mult
                div "#{total_storaege} GB total"
            tr
              th
                Tooltip {
                  mount_point_y : "bottom"
                  position_y    : "top"
                  tooltip_render : ()=>
                    div {
                      style :
                        background  : "#fff"
                        padding     : 5
                        borderRadius: 5
                        border      : "1px solid #000"
                        fontFamily  : "monospace"
                        fontWeight  : "normal"
                        whiteSpace  : "nowrap"
                        textAlign   : "left"
                    }
                      div
                        span "You need to know your real "
                        b "random"
                        span " read performance"
                      div
                        span "Vendors usually specify "
                        b "linear"
                        span " read performance"
                      div
                        b dangerouslySetInnerHTML: __html : "proper benchmark &nbsp;"
                        span "fio -ioengine=libaio -direct=1 -buffered=0 -invalidate=1 -name=test -bs=256k -iodepth=32 -rw="
                        b "randread"
                        " -runtime=60 -filename=/dev/sdX (your disk)"
                      div
                        b "invalid benchmark "
                        span " fio -ioengine=libaio -direct=1 -buffered=0 -invalidate=1 -name=test -bs=256k -iodepth=32 -rw="
                        b "read"
                        " -runtime=60 -filename=/dev/sdX (your disk)"
                }
                  div {style:cursor:"pointer"}, "Storage type (?)"
              list = [
                {
                  type : "nvme_pcie4"
                  title: "NVMe (PCI-E gen 4 port max)"
                }
                {
                  type : "nvme_pcie3"
                  title: "NVMe (PCI-E gen 3 port max)"
                }
                {
                  type : "nvme_pcie2"
                  title: "NVMe (PCI-E gen 2 port max)"
                }
                {
                  type : "nvme_pcie4_typ"
                  title: "NVMe (PCI-E gen 4 typical 2GB/s)"
                }
                {
                  type : "nvme_pcie3_typ"
                  title: "NVMe (PCI-E gen 3 typical 1GB/s)"
                }
                {
                  type : "sata3_ssd"
                  title: "SATA3 SSD"
                }
                {
                  type : "sata2_ssd"
                  title: "SATA2 SSD"
                }
                {
                  type : "hdd"
                  title: "HDD"
                }
              ]
              td {
                colSpan : 4
              }
                for v in list
                  do (v)=>
                    on_click = ()=>
                      @set_state storage_type : v.type
                      call_later ()=> @calculate_spora_hashrate()
                    div {
                      style :
                        width : "100%"
                    }
                      input {
                        id   : v.type
                        type : "radio"
                        checked : @state.storage_type == v.type
                        style :
                          cursor : "pointer"
                        on_click
                      }
                      label {
                        for : v.type
                        style :
                          cursor : "pointer"
                        on_click
                      }, v.title
            tr
              th "Storage count"
              td {
                colSpan : 3
              }
                Number_input {
                  value : @state.storage_count
                  on_change : (storage_count)=>
                    storage_count = Math.max 1, storage_count
                    @set_state {storage_count}
                    call_later ()=>@calculate_spora_hashrate()
                }
              td
                if @state.storage_count > 1
                  "RAID efficiency #{@state.raid_effificency}"
            if @state.storage_count > 1
              tr
                th "RAID type"
                td {
                  colSpan : 3
                }
                  list = [
                    {
                      type : "raid0"
                      title: "RAID0"
                    }
                    {
                      type : "manual"
                      title: "Manual"
                    }
                  ]
                  for v in list
                    do (v)=>
                      on_click = ()=>
                        @set_state
                          raid_type : v.type
                          raid_effificency : raid_type_to_efficiency_hash[v.type]
                        call_later ()=> @calculate_spora_hashrate()
                      div {
                        style :
                          width : "100%"
                      }
                        input {
                          id   : v.type
                          type : "radio"
                          checked : @state.raid_type == v.type
                          style :
                            cursor : "pointer"
                          on_click
                        }
                        label {
                          for : v.type
                          style :
                            cursor : "pointer"
                          on_click
                        }, v.title
                td {}
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
                      }
                        div "Manual means you are manually distribute files (e.g. with symlinks)"
                        div "(more complex variant - fragmented JBOD. Split all disks to 100GB chunks and merge them in JBOD. Will have +- same effect for IOPS distribution)"
                  }
                    div {style:cursor:"pointer"}, "(?)"
                  
              
          hashrate_ratio = @state.spora_hashrate / (@state.net_hashrate + @state.spora_hashrate)
          if @state.hashrate_mode in ["randomx", "cpu"]
            tr
              th "SPoRA hashrate CPU limiter"
              td {
                colSpan : 3
              }, "#{@state.spora_hashrate_cpu.toFixed 2}"
              td
                if @state.spora_hashrate_cpu == @state.spora_hashrate
                  span "bottleneck"
                else
                  utilization = @state.spora_hashrate / @state.spora_hashrate_cpu
                  span "utilization #{(100*utilization).toFixed 2}% "
                  if utilization < 0.2
                    span {style:backgroundColor:"#ff0000"}, "very low"
                  else if utilization < 0.5
                    span {style:color:"#ff0000"}, "low"
                  else if utilization < 0.8
                    span {style:color:"#ffa000"}, "suboptimal"
            tr
              th "SPoRA hashrate storage bandwidth limiter"
              td {
                colSpan : 3
              }, "#{@state.spora_hashrate_storage.toFixed 2}"
              td 
                if @state.spora_hashrate_storage == @state.spora_hashrate
                  span "bottleneck"
                else
                  utilization = @state.spora_hashrate / @state.spora_hashrate_storage
                  span "utilization #{(100*utilization).toFixed 2}% "
                  if utilization < 0.2
                    span {style:backgroundColor:"#ff0000"}, "very low"
                  else if utilization < 0.5
                    span {style:color:"#ff0000"}, "low"
                  else if utilization < 0.8
                    span {style:color:"#ffa000"}, "suboptimal"
            tr
              th "SPoRA hashrate storage iops limiter"
              td {
                colSpan : 3
              }, "#{@state.spora_hashrate_iops.toFixed 2}"
              td
                if @state.spora_hashrate_iops == @state.spora_hashrate
                  span "bottleneck"
                else
                  utilization = @state.spora_hashrate / @state.spora_hashrate_iops
                  span "utilization #{(100*utilization).toFixed 2}%"
          tr
            th "SPoRA hashrate"
            td {
              colSpan : 2
            }
              Number_input {
                value : @state.spora_hashrate
                on_change : (spora_hashrate)=>
                  @set_state {spora_hashrate}
                  call_later ()=>@calculate_spora_hashrate()
                disabled : @state.hashrate_mode != "spora"
              }
              span " h/s"
            td {
              colSpan : 2
            }
              div "#{(100*hashrate_ratio).toFixed 6}% of network"
              p_per_hash= 1/@state.hash_count_per_block_avg
              p_per_day = 1-(1-p_per_hash)**(24*60*60*@state.spora_hashrate)
              div "#{(p_per_day*100).toFixed(2)}% probability to find 1+ block per day solo"
          tr
            th
              
              Tooltip {
                mount_point_y : "bottom"
                position_y    : "top"
                tooltip_render : ()=>
                  div {
                    style :
                      background  : "#fff"
                      padding     : 5
                      borderRadius: 5
                      border      : "1px solid #000"
                      fontFamily  : "monospace"
                      fontWeight  : "normal"
                      whiteSpace  : "nowrap"
                      textAlign   : "left"
                  }
                    div
                      span "Results may differ from chronobot's reported difficulty #{@state.net_hashrate_v1.to_format_float_string 0} h/s"
                    div
                      span "(just avaraged per block)"
              }
                div {style:cursor:"pointer"}
                  span "SPoRA net hashrate (?)"
              
            td {
              colSpan : 4
            }
              div
                span "#{@state.net_hashrate.to_format_float_string 0} h/s"
              div
                span "(avg last #{h_count block_height_hash} blocks weighted by "
                b "real"
                span " block time of "
                b "each"
                span " block)"
          tr
            th {colSpan:5}, "Economics"
          tr
            th "Exchange rate"
            td {
              colSpan : 4
            }
              Number_input {
                value : @state.exchange_rate
                on_change : (exchange_rate)=>
                  exchange_rate = Math.max 0, exchange_rate
                  @set_state {exchange_rate}
              }
              span " USD/AR "
              if @state.exchange_rate_is_loading
                Spinner {}
              else if @state.exchange_rate_load_error
                span "load error"
              if !@state.exchange_rate_is_loading
                Button {
                  label : "Refresh"
                  on_click : ()=>@exchange_rate_refresh()
                }
              span " (binance 24h weighted avg)"
          tr
            th "Block reward"
            td {
              colSpan : 4
            }
              Number_input {
                value : @state.block_reward
                disabled : true
                on_change : (block_reward)=>
                  @set_state {
                    block_reward
                  }
                  call_later ()=>@calculate_spora_hashrate()
              }
              span " (avg of last #{@state.block_reward_count} blocks with fully known rewards)"
          tr
            th "Pool fee"
            td {
              colSpan : 4
            }
              Checkbox {
                value : @state.pool_fee_enabled
                on_change : (pool_fee_enabled)=>
                  @set_state {pool_fee_enabled}
                  call_later ()=>@calculate_spora_hashrate()
              }
              span " (virdpool fee is #{(@state.pool_fee*100).toFixed(0)}%)"
          list = [
            {
              title : "month"
              mult  : 30*24*60*60
            }
            {
              title : "week"
              mult  : 7*24*60*60
            }
            {
              title : "day"
              mult  : 24*60*60
            }
            {
              title : "hour"
              mult  : 60*60
            }
          ]
          ar_per_sec = hashrate_ratio * @state.block_reward / block_time
          if @state.pool_fee_enabled
            ar_per_sec *= 1 - @state.pool_fee
          for v in list
            tr
              th "Profit per #{v.title}"
              td {
                style:
                  textAlign : "right"
                  width : 100
              }
                val = v.mult * ar_per_sec
                span "#{val.toFixed 2}"
              td {
                style:
                  width : 100
              }, "AR/#{v.title}"
              td {
                style:
                  textAlign : "right"
                  width : 100
              }
                val = v.mult * ar_per_sec * @state.exchange_rate
                span "#{val.toFixed 2}"
              td {
                style:
                  width : 300 # because special column
              }, "USD/#{v.title}"
