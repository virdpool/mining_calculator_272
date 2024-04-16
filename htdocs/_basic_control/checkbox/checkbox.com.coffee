module.exports =
  mount_done : ()->
    @indeterminate_from_props @props
  
  props_change : (props)->
    @indeterminate_from_props props
  
  indeterminate_from_props : (props)->
    @refs.input.indeterminate = typeof props.value != "boolean"
    return
  
  render : ()->
    span {
      on_click : @on_change
      style: Object.assign {
        cursor: if @props.disabled then "" else "pointer"
      }, @props.parent_style or {}
      
      on_hover  : ()=>@props.on_hover?()
      # on_blur   : ()=>@props.on_blur?()
      on_mouse_out: ()=>
        @props.on_mouse_out?()
        @props.on_blur?()
    }
      input {
        ref       : "input"
        id        : @props.id
        class     : @props.class
        style     : Object.assign {
          cursor: if @props.disabled then "" else "pointer"
        }, @props.style or {}
        disabled  : @props.disabled
        
        type      : "checkbox"
        checked   : @props.value or false
        # on_change : @on_change # will trigger double event
      }
      @props.label or @props.children
    
  on_change : (event)->
    return if @props.disabled
    value = !(@props.value or false)
    @props.on_change value
    @props.on_click? event, value
    return
  