# TODO touch events. Maybe Hammer
module.exports =
  mounted : false
  mount_done : ()->
    @mounted = true
    draw = ()=>
      return if !@mounted
      canvas_hash = @canvas_actualize()
      requestAnimationFrame draw
      @props.canvas_cb? canvas_hash
    draw()
    @props.ref_textarea? @get_textarea()
  
  get_textarea : ()->
    @props.textarea or @refs.textarea
  
  unmount : ()->
    @mounted = false
  
  props_change : (new_props)->
    if @props.layer_list != new_props.layer_list
      for layer in new_props
        @props.gui?.refresh layer
    return
  
  old_width     : 0
  old_height    : 0
  old_layer_list: []
  old_canvas_hash : {}
  canvas_actualize : ()->
    {box} = @refs
    {width, height} = box.getBoundingClientRect()
    return @old_canvas_hash if @old_width == width and @old_height == height and @old_layer_list == @props.layer_list
    
    @old_width  = width
    @old_height = height
    @old_layer_list = @props.layer_list
    
    canvas_list = []
    for name in @props.layer_list
      continue if !canvas = @refs[name]
      canvas_list.push canvas
    
    width  = @props.width  if @props.width
    height = @props.height if @props.height
    width  = @props.size_x if @props.size_x
    height = @props.size_y if @props.size_y
    
    width = Math.floor width *devicePixelRatio
    height= Math.floor height*devicePixelRatio
    if @props.resize_fix != false
      width -= 1
      height-= 1
    
    for canvas,idx in canvas_list
      if canvas.width != width or canvas.height != height
        canvas.width  = width
        canvas.height = height
        @props.gui?.refresh @props.layer_list[idx]
    
    canvas_hash = {}
    for name in @props.layer_list
      canvas_hash[name] = @refs[name]
    
    @old_canvas_hash = canvas_hash
  
  render : ()->
    div { # this is only measuring box (resize sensor), we don't need set it real size from props
      ref   : "box"
      style :
        width   : "100%"
        height  : "100%"
    }
      for name in @props.layer_list or []
        # div {
          # style:
            # position: "relative"
        # }
          canvas {
            ref   : name
            style :
              position: "absolute"
              # width   : "100%"
              # height  : "100%"
            
            on_click    : @mouse_click
            onMouseDown : @mouse_down
            onMouseUp   : @mouse_up
            onMouseMove : @mouse_move
            onMouseOut  : @mouse_out
            onWheel     : @mouse_wheel
          }
      if !@props.textarea or @props.no_textarea
        textarea {
          ref       : "textarea"
          onKeyDown : @key_down
          onKeyUp   : @key_up
          onKeyPress: @key_press
          onBlur    : @focus_out
          style :
            position: "absolute"
            # top     : 0 # DEBUG
            # left    : 0 # DEBUG
            top     : -1000
            left    : -1000
        }
  
  key_down    : (event)->@props.gui?.key_down?(event)
  key_up      : (event)->@props.gui?.key_up?(event)
  key_press   : (event)->@props.gui?.key_press?(event)
  
  mouse_click : (event)->
    @get_textarea()?.focus()
    @props.gui?.mouse_click?(event, @props.layer_list[0])
  
  mouse_down  : (event)->@props.gui?.mouse_down?(event, @props.layer_list[0])
  mouse_up    : (event)->
    @get_textarea()?.focus()
    @props.gui?.mouse_up?(event, @props.layer_list[0])
  
  mouse_out   : (event)->@props.gui?.mouse_out?(  event, @props.layer_list[0])
  mouse_move  : (event)->@props.gui?.mouse_move?( event, @props.layer_list[0])
  mouse_wheel : (event)->@props.gui?.mouse_wheel?(event, @props.layer_list[0])
  focus_out   : (event)->@props.gui?.focus_out?(  event, @props.layer_list[0])
  