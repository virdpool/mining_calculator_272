Number.prototype.to_format_int_string = ()->
  @toString().reverse().split(/(...)/).join(" ").reverse().trim().replace("- ", "-")

String.prototype.to_format_int_string = ()->
  @reverse().split(/(...)/).join(" ").reverse().trim().replace("- ", "-")

Number.prototype.to_format_float_string = (decimals = 2)->
  if decimals == 0
    return @.toFixed(0).to_format_int_string()
  [main, frac] = @toFixed(decimals).split(".")
  main =  main.reverse().split(/(...)/).join(" ").reverse().trim().replace("- ", "-")
  "#{main}.#{frac}"
