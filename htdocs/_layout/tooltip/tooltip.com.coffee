default_mount_point_x = "center"
default_position_x    = "center"

default_mount_point_y = "top"
default_position_y    = "bottom"

module.exports =
  state:
    c_hover  : false # container hover
    tc_hover : false # tooltip_container hover
  
  # instant state
  c_hover : false
  tc_hover: false
  
  render : ()->
    show_lag = @props.show_lag or 20
    hide_lag = @props.hide_lag or 100 # should be > 0 for tc_hover proper work
    
    # if @props.show is supplied then manual
    # if @props.show is not supplied then auto (on c_hover or tc_hover)
    
    div {
      style: Object.assign {
        display: "inline-block"
      }, @props.style
    }
      div {
        ref:"container"
        style:
          display: "inline-block"
        
        on_hover    : ()=>
          return if @props.show?
          @c_hover = true
          setTimeout ()=>
            @set_state c_hover: @c_hover
          , show_lag
        
        on_mouse_out: ()=>
          return if @props.show?
          @c_hover = false
          setTimeout ()=>
            @set_state c_hover: @c_hover
          , hide_lag
      
      }, @props.children # WTF?
      if @props.show?
        show = @props.show
      else
        show = @state.c_hover or @state.tc_hover
      
      if show
        opacity = 1
        if @refs.container
          container = @refs.container.getBoundingClientRect()
        else
          opacity = 0
          container = {x:0,y:0,width:0, height:0}
        
        if @refs.tooltip_container
          tooltip_container = @refs.tooltip_container.getBoundingClientRect()
        else
          opacity = 0
          tooltip_container = {width:0, height:0}
          setTimeout ()=> @force_update()
        
        
        offset_x = 0
        offset_y = 0
        # offset x
        switch @props.mount_point_x or default_mount_point_x
          # when "left"
            # offset_x += 0
          when "center", "middle"
            offset_x += container.width/2
          when "right"
            offset_x += container.width
        
        switch @props.position_x or default_position_x
          when "left"
            offset_x -= tooltip_container.width
          when "center", "middle"
            offset_x -= tooltip_container.width/2
          # when "right"
            # offset_x -= 0
          
        # offset y
        switch @props.mount_point_y or default_mount_point_y
          when "top"
            offset_y -= container.height
          when "center", "middle"
            offset_y -= container.height/2
          # when "bottom"
            # offset_y -= 0
        
        switch @props.position_y or default_position_y
          when "top"
            offset_y -= 0
          when "center", "middle"
            offset_y -= tooltip_container.height/2
          when "bottom"
            offset_y -= tooltip_container.height
        
        # fix out of bounds
        # LEFT, TOP
        real_x = container.x + (container.width - tooltip_container.width)/2
        offset_x -= real_x if real_x < 0
        
        real_y = container.y + (container.height - tooltip_container.height)/2
        offset_y -= real_y if real_y < 0
        # TODO RIGHT, BOTTOM
        
        div {
          style :
            position: "relative"
            left    : offset_x
            top     : offset_y
            opacity : opacity
        }
          div {
            ref: "tooltip_container"
            style :
              position: "absolute"
            on_hover    : ()=>
              return if @props.show?
              @tc_hover = true
              setTimeout ()=>
                @set_state tc_hover: @tc_hover
              , show_lag
            
            on_mouse_out: ()=>
              return if @props.show?
              @tc_hover = false
              setTimeout ()=>
                @set_state tc_hover: @tc_hover
              , hide_lag
          }
            @props.tooltip_render()
