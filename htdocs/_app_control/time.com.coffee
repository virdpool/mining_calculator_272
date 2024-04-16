module.exports =
  render : ()->
    date = dayjs(@props.value*1000)
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
        }, date.format("HH:mm:ss DD.MM.YYYY")
    }
      span date.fromNow()