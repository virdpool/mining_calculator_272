module.exports =
  render : ()->
    if !list = @props.list
      list = []
      # alternative
      for k,v of @props.hash or {}
        list.push {value: k, title: v}
    
    {value} = @props
    div {
      id        : @props.id
      class     : @props.class
      style     : @props.style
      disabled  : @props.disabled
      
      value     : @props.value
      
      onFocus     : ()=>@props.on_focus?()
      onBlur      : ()=>@props.on_blur?()
      on_hover    : ()=>@props.on_hover?()
      on_mouse_out: ()=>@props.on_mouse_out?()
    }
      for v in list
        do (v)=>
          title = v.title ? (if v.value?.toString then v.value.toString() else null) ? ""
          div {
            on_click : ()=>
              @force_update()
              @props.on_change v.value
            style :
              cursor : "pointer"
          }
            input {
              type: "radio"
              checked : v.value == value
              style :
                cursor : "pointer"
            }
            span title
  

