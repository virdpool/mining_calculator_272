module.exports =
  state : 
    filter  : ""
    sort    : ""
    sort_dir: ""
  render : ()->
    col_list = @props.col_list or []
    $col_list = []
    for col in col_list
      do (col)=>
        $col_list.push th {
          class : if col.sort or @props.sort then "sort "+(if col.key == @state.sort then @state.sort_dir else "") else ""
          on_click : ()=>
            return if !col.sort and !@props.sort
            if @state.sort != col.key
              @set_state {
                sort : col.key
                sort_dir : "asc"
              }
            else
              @set_state {
                sort_dir : if @state.sort_dir == "asc" then "desc" else "asc"
              }
            return
        }, col.title or col.key
    
    data = @props.data or @props.list or [] # alias
    if @state.filter
      # TODO later highlight on match
      filter_chunk_list = @state.filter.toLowerCase().split /\s+/g
      if filter_chunk_list.length
        filter_data = []
        for row in data
          pass_all = true
          for filter in filter_chunk_list
            pass = false
            for k,v of row
              if typeof v == "string"
                v = v.toLowerCase()
              else if typeof v == "number"
                v = v.toString()
              else
                continue
              
              if -1 != v.indexOf filter
                pass = true
                break
            if !pass
              pass_all = false
              break
          if pass_all
            filter_data.push row
        data = filter_data
      
    if @state.sort
      data = data.clone()
      field = @state.sort
      if row = data[0]
        if typeof row[field] == "string"
          if @state.sort_dir == "asc"
            data.sort (a,b)-> (a[field] or "").localeCompare(b[field])
          else
            data.sort (a,b)->-(a[field] or "").localeCompare(b[field])
        else if typeof row[field] == "number"
          if @state.sort_dir == "asc"
            data.sort (a,b)-> (a[field] - b[field])
          else
            data.sort (a,b)->-(a[field] - b[field])
      
    
    $row_list = []
    for row in data
      $row_list.push tr =>
        ret = []
        for col in col_list
          col.renderer ?= col.render # Дружественны к опечаткам
          if col.renderer
            ret.push td col.renderer row[col.key], row, @
          else
            ret.push td row[col.key]
        return ret
    div
      if @props.filter
        Text_input {
          value     : @state.filter
          on_change : (filter)=> @set_state {filter}
          placeholder : "Filter by all fields"
        }
      table {class:"table"}
        tbody
          tr $col_list
          return $row_list
  props_change : ()->
    @force_update()