module.exports =
  hw_render : ()->
    tr
      th {colSpan:5}, "Hardware"
    # TODO VDF
    tr
      th
      td {colSpan:4}
        table {
          class : "table"
          style :
            width : "100%"
        }
          total_tb = 0
          total_read_mb_s = 0
          max_read_mb_s   = 0
          partition_count = 0
          tbody
            tr
              th "Count"
              th "Capacity TB"
              th "Read MB/s"
              th
            for hdd in @props.hdd_config
              do (hdd)=>
                total_tb        += hdd.count * hdd.size_tb
                max_read_per_hdd = 200 * hdd.size_tb / 4 
                total_read_mb_s += hdd.count * Math.min hdd.read_mb_s, max_read_per_hdd
                max_read_mb_s   += hdd.count * max_read_per_hdd
                partition_count += hdd.count * hdd.size_tb / 4 
                tr
                  td
                    Number_input {
                      value : hdd.count
                      on_change : (value)=>
                        hdd.count = value
                        @props.on_change_hdd_config()
                      style:
                        width : "100%"
                    }
                  td
                    Number_input {
                      value : hdd.size_tb
                      on_change : (value)=>
                        hdd.size_tb = value
                        @props.on_change_hdd_config()
                      style:
                        width : "100%"
                    }
                  td
                    Number_input {
                      value : hdd.read_mb_s
                      on_change : (value)=>
                        hdd.read_mb_s = value
                        @props.on_change_hdd_config()
                      style:
                        width : "100%"
                    }
                  td
                    Button {
                      label : "x"
                      on_click : ()=>
                        @props.hdd_config.remove hdd
                        @props.on_change_hdd_config()
                      style :
                        backgroundColor : "#FAA"
                    }
            tr
              td {colSpan:4}
                Button {
                  label : "Add"
                  on_click : ()=>
                    @props.hdd_config.push {
                      size_tb   : 4
                      count     : 10
                      read_mb_s : 150
                    }
                    @props.on_change_hdd_config()
                  style:
                    width : "100%"
                }
            tr
              th {colSpan:4}, "Total"
            tr
              td {
                style :
                  textAlign : "center"
              }, partition_count.to_format_float_string().replace(".00", "") + " partitions"
              td {
                style :
                  textAlign : "center"
              }, total_tb.to_format_int_string() + " TB"
              td {
                style :
                  textAlign : "center"
              }
                mbs_min = total_read_mb_s.to_format_int_string()
                mbs_max = max_read_mb_s  .to_format_int_string()
                rate = total_read_mb_s/max_read_mb_s
                "#{mbs_min} /  #{mbs_max} MB/s (#{(rate*100).toFixed(2).replace('.00', '')}%)"
              td
                # TOOD (?)
  
  # ###################################################################################################
  #    render
  # ###################################################################################################
  render : ()->
    div
      h3 "Arweave profit and hashrate calculator"
      table {
        class : "table"
        style :
          width : 1050
      }
        tbody
          tr
            th {
              style :
                width : 400
            }
            td {colSpan:4}
              Select_radio {
                value : @props.mode
                on_change : @props.on_change_mode
                hash :
                  hashrate : "I know my hashrate"
                  hdd      : "I have some HDD (or will buy)"
              }
          if @props.mode == "hdd"
            @hw_render()
          if @props.mode == "hdd"
            tr
              th {colSpan:5}, "Weave size"
            tr
              th "My downloaded unique weave size"
              td {colSpan:4}
                Number_input {
                  value : @props.weave_size_tb
                  on_change : @props.on_change_weave_size_tb
                }
                total_size_tb = @props.network_weave_size
                if @props.mode == "hdd"
                  total_size_tb = 0
                  for hdd in @props.hdd_config
                    total_size_tb += hdd.count * hdd.size_tb
                
                min_size_tb = Math.min total_size_tb, @props.weave_size_tb
                rate = min_size_tb/(@props.network_weave_size/1024**4)
                rate = Math.min rate, 1
                if total_size_tb > @props.weave_size_tb
                  span " TB (#{(rate*100).toFixed(2)}%)"
                else
                  span " TB (#{(rate*100).toFixed(2)}%) (HDD capacity is not enough to fit all)"
            tr
              th "Network weave size"
              td {colSpan:4}
                (@props.network_weave_size/1024**4).to_format_float_string() + " TB"
          tr
            th {colSpan:5}, "Hashrate"
          tr
            if @props.mode == "hdd"
              th "My hashrate full:#{@props.full_replica_count} part:#{(@props.part_replica_count*100).toFixed(2)}%"
            else
              th "My hashrate"
            td
              Number_input {
                value     : @props.hashrate
                on_change : @props.on_change_hashrate
                disabled  : @props.mode == "hdd"
              }
              span " h/s"
            td {colSpan:3}
              percent = @props.hashrate/@props.network_hashrate*100
              div "#{percent.toFixed(2)}% of network"
              div "#{(@props.block_prob_per_day*100).toFixed(2)}% probability to find 1+ block per day solo"
          tr
            th "Net hashrate"
            td {colSpan:4}
              div "#{@props.network_hashrate.to_format_int_string()} h/s"
              # TODO
              div
                span "(avg last #{@props.stat_block_count} blocks weighted by "
                b "real"
                span " block time of "
                b "each"
                span " block)"
          tr
            th {colSpan:5}, "Economics"
          tr
            th "Exchange rate"
            td {colSpan:4}
              Number_input {
                value : @props.exchange_rate
                on_change : @props.on_change_exchange_rate
                
              }
              span " USD/AR "
              Button {
                label : "Refresh"
                on_click : ()=>
                  @props.on_exchange_rate_refresh()
              }
              span " (binance 24h weighted avg)"
          tr
            th "Block reward"
            td {colSpan:4}
              Number_input {
                value   : @props.block_reward
                disabled: true
              }
              span " AR (avg of last 100 blocks with fully known rewards)"
          #tr
          #  th "Pool fee"
          #  td {colSpan:4}
          #    Checkbox {
          #      value : @props.include_pool_fee
          #      on_change : @props.on_change_include_pool_fee
          #      
          #      label : "(virdpool fee is #{(@props.pool_fee*100).toFixed(0)}%)"
          #    }
          
      table {
        class : "table"
        style :
          width : 1050
          marginTop : -1
      }
        tbody
          {
            profit_per_day
            exchange_rate
          } = @props
          mult_descriptor_list = [
            {
              title : "month"
              mult : 30
            }
            {
              title : "week"
              mult : 7
            }
            {
              title : "day"
              mult : 1
            }
            {
              title : "hour"
              mult : 1/24
            }
          ]
          for mult_descriptor in mult_descriptor_list
            {mult, title} = mult_descriptor
            tr
              th {
                style :
                  width : 400
              }, "Profit per #{title}"
              td {
                style:
                  width : 100
                  textAlign : "right"
              }, (mult*profit_per_day).to_format_float_string()
              td "AR/#{title}"
              td  {
                style:
                  width : 100
                  textAlign : "right"
              }, (mult*profit_per_day*exchange_rate).to_format_float_string()
              td "USD/#{title}"
            

