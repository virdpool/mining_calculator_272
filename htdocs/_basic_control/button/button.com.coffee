module.exports =
  render : ()->
    button {
      id        : @props.id
      class     : @props.class
      style     : @props.style
      disabled  : @props.disabled
      
      on_click  : (event)=>@props.on_click?(event)
      on_hover  : (event)=>@props.on_hover?(event)
      # on_blur   : ()=>@props.on_blur?()
      on_mouse_out: ()=>
        @props.on_mouse_out?()
        @props.on_blur?()
    }, @props.label