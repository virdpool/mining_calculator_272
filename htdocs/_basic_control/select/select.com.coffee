module.exports =
  render : ()->
    $list = []
    for v in @props.list or []
      $list.push option {value:v.value}, v.title or (if typeof v.value == "string" then v.value else null) or ""
    select {
      id        : @props.id
      class     : @props.class
      style     : @props.style
      disabled  : @props.disabled
      
      value     : @props.value
      on_change : @on_change
      
      onFocus     : ()=>@props.on_focus?()
      onBlur      : ()=>@props.on_blur?()
      on_hover    : ()=>@props.on_hover?()
      on_mouse_out: ()=>@props.on_mouse_out?()
    }, $list
    
  on_change : (event)->
    value = event.target.value
    @props.on_change(value)
    return
