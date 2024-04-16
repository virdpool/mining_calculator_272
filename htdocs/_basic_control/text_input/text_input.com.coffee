module.exports =
  mount_done : ()->
    @props.ref_cb? @refs.element
    if @props.autofocus
      @refs.element.focus()
  
  render : ()->
    input obj_set {}, @props, {
      ref         : "element"
      
      type        : "text"
      value       : @props.value or ""
      on_change   : @on_change
      on_key_press: (event)=>
        if event.nativeEvent.which == 13 # ENTER
          @props.on_enter?(event)
        @props.on_key_press?(event)
        return
    }
    
  on_change : (event)->
    value = event.target.value
    @props.on_change(value)
    return
