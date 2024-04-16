module.exports =
  render : ()->
    if location.hash == @props.href
      span @props, @props.label ? @props.href
    else
      a @props, @props.label ? @props.href
