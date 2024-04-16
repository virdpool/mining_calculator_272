module.exports =
  render : ()->
    if @props.value == 0
      label = "?"
      real_val = "?"
    else
      label = winston_to_ar_format @props.value
      real_val = winston_to_ar @props.value
    
    if +label != real_val
      Tooltip {
        tooltip_render : ()=>
          div {
            style :
              background  : "#fff"
              padding     : 5
              borderRadius: 5
              border      : "1px solid #000"
          }, real_val
      }
        span label
    else
      span label