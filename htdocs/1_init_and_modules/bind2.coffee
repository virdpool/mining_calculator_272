window.bind2 = (athis, key, opt={})->
  Object.assign {}, opt, {
    value     : athis.state[key]
    on_change : (value)->
      state = {}
      state[key] = value
      athis.set_state state
      opt.on_change?(value)
  }

# ###################################################################################################
#    local (per component)
# ###################################################################################################
window.load_ls = (athis, key)->
  local_storage_key = "#{athis.name}.#{key}"
  value = null
  if stored_value_json = localStorage.getItem(local_storage_key)
    try
      value = JSON.parse stored_value_json
    catch err
      perr err
      # nothing

window.bind2ls = (athis, key, opt={})->
  local_storage_key = "#{athis.name}.#{key}"
  value = load_ls athis, key
  
  if opt.value_preprocess
    value = opt.value_preprocess value
  Object.assign {}, opt, {
    value
    on_change : (value)->
      localStorage.setItem local_storage_key, JSON.stringify value
      opt.on_change? value
      athis.force_update()
  }

# ###################################################################################################
#    global
# ###################################################################################################
window.load_lsg = (athis, key)->
  local_storage_key = "global.#{key}"
  value = null
  if stored_value_json = localStorage.getItem(local_storage_key)
    try
      value = JSON.parse stored_value_json
    catch err
      perr err
      # nothing

window.bind2lsg = (athis, key, opt={})->
  local_storage_key = "global.#{key}"
  value = load_lsg athis, key
  
  if opt.value_preprocess
    value = opt.value_preprocess value
  Object.assign {}, opt, {
    value
    on_change : (value)->
      localStorage.setItem local_storage_key, JSON.stringify value
      opt.on_change? value
      athis.force_update()
  }


window.save_ls = (athis, key, value, opt={force_update:true})->
  local_storage_key = "#{athis.name}.#{key}"
  if value == undefined
    localStorage.removeItem local_storage_key
  else
    localStorage.setItem local_storage_key, JSON.stringify value
  
  if opt.force_update
    athis.force_update()
  return
