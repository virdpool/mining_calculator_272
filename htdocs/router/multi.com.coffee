module.exports =
  state : {
    router_hash : {}
  }
  mount : ()->
    @location_change()
    window.onpopstate = ()=>@location_change()
    window.route_go = (path, key = "")=>
      @state.router_hash[key] ?= {
        path : ""
        split: []
      }
      @state.router_hash[key].path = path
      chunk_list = []
      route_delimiter = @props.route_delimiter or "/"
      subroute_delimiter = @props.subroute_delimiter or ";"
      for key, v of @state.router_hash
        chunk_list.push "#{key}#{route_delimiter}#{v.path}"
      location.hash = chunk_list.join subroute_delimiter
      @location_change()
      return
    return
  
  location_change : ()->
    router_hash = {}
    hash = location.hash.replace /^#/, ""
    subroute_delimiter = @props.subroute_delimiter or ";"
    route_delimiter = @props.route_delimiter or "/"
    for sub_route in hash.split subroute_delimiter
      split = sub_route.split route_delimiter
      key = split.shift()
      path = split.join route_delimiter
      router_hash[key] = {
        path
        split
      }
    @set_state {router_hash}
    return
  
  render : ()->
    @props.render @state.router_hash
