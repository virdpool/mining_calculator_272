module.exports =
  render : ()->
    label = @props.value
    wide = @props.wide
    
    label = label.cut_mid 16 if !wide
    
    route = "block/#{@props.value}"
    if !wide
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
          }, @props.value
      }
        @link_render route, label
    else
      @link_render route, label
  
  link_render : (route, label)->
    Link {
      href  : "#/#{route}"
      label
      style :
        fontFamily: "monospace"
      on_click : (e)=>
        e.stopPropagation()
        route_go route
    }
