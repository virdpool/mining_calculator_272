# credits https://stackoverflow.com/questions/43087492/spinner-with-transparent-background
module.exports =
  render : ()->
    size = @props.size or 10
    div {
      class: "smt-spinner-circle"
      style:
        width : size
        height: size
    }
      div {
        class : "smt-spinner"
      }
