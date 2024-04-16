module.exports =
  render : ()->
    div {
      class : "tab"
      style : @props.style
    }
      # BUG
      # style = if @props.center then {margin:"0 auto"} else {}
      style     = if @props.center then {margin:"0 auto"} else {};
      btn_style = if @props.center then {} else {float:"left"};
      obj_set btn_style, @props.btn_style if @props.btn_style
      div {style}
        for k,v of @props.hash or {}
          do (k,v)=>
            # TODO better design
            Button {
              class : if @props.value == k then "active" else ""
              label : v
              on_click: ()=>@props.on_change k
              style : btn_style
            }
  