module.exports =
  render : ()->
    textarea {
      id        : @props.id
      class     : @props.class
      style     : @props.style
      disabled  : @props.disabled
      readonly  : @props.readonly
      
      type        : "text"
      value       : @props.value or ""
      on_change   : @on_change
      placeholder : @props.placeholder
      cols        : @props.cols
      rows        : @props.rows
      
      onFocus     : ()=>@props.on_focus?()
      onBlur      : ()=>@props.on_blur?()
      on_hover    : ()=>@props.on_hover?()
      on_mouse_out: ()=>@props.on_mouse_out?()
    }
    
  on_change : (event)->
    value = event.target.value
    @props.on_change(value)
    return
