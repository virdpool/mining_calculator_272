String.prototype.cut = (limit)->
  if @length < limit
    return ""+@ # иначе вернет объект типа String
  @substr(0, limit)+"..."

String.prototype.cut_mid = (limit)->
  if @length < limit
    return ""+@ # иначе вернет объект типа String
  @substr(0, limit/2)+"..."+@substr(@length - limit/2)
