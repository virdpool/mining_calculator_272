module.exports =
  render : ()->
    table {
      class : "group table_drop_spacing"
      style : @props.style
    }
      tbody
        tr {
          class : "group-title"
        }
          td @props.label_fn() if @props.label_fn?
          td @props.label if @props.label?
        tr {
          class : "group-body"
          style : @props.body_style
        }
          td @props.children
