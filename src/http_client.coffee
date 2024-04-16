module = @
http  = require "http"
https = require "https"
axios = require "axios"
config = require "./config"

axios_instance = axios.create {
  httpAgent : new http.Agent keepAlive: true
  httpsAgent: new https.Agent keepAlive: true
}

class @Single_node_client
  url: ""
  
  url_to_err_hash : {}
  
  is_under_429_delay : false
  
  constructor : (@url)->
    @url_to_err_hash = {}
    # TODO cleanup interval
  
  # ###################################################################################################
  #    util
  # ###################################################################################################
  _http_request : (opt, cb)->
    {
      url
      axios_opt
    } = opt
    opt.json ?= true
    @last_url = url
    if err = @url_to_err_hash[url]
      if Date.now() - err.ts < config.arweave_http_client_err_cache_ts
        puts "prevent request", url
        return cb err
    await axios_instance.get(url, axios_opt).cb defer(err, res);
    if err?.message == "Request failed with status code 429"
      puts "429 delay", url
      @is_under_429_delay = true
      do ()=>
        await setTimeout defer(), config.arweave_http_client_429_ts
        @is_under_429_delay = false
    
    if err
      err.ts  = Date.now()
      err.url = url
      @url_to_err_hash[url] = err
      return cb err
    
    cont = res.data
    json = null
    if opt.json
      try
        json = JSON.parse cont
      catch err
        err.ts  = Date.now()
        err.url = url
        err.cont= cont
        return cb err
    
    cb null, {json, cont}
  
  http_json_cont : (url, cb)->
    loc_opt = {
      url
      axios_opt :
        transformResponse : []
        timeout: config.arweave_http_client_long_http_timeout
    }
    @_http_request loc_opt, cb
  
  http_json_cont_fast : (url, cb)->
    loc_opt = {
      url
      axios_opt :
        transformResponse : []
        timeout: config.arweave_http_client_short_http_timeout
    }
    @_http_request loc_opt, cb
  
  http_cont_fast : (url, cb)->
    loc_opt = {
      url
      axios_opt :
        transformResponse : []
        timeout: config.arweave_http_client_short_http_timeout
      json : false
    }
    @_http_request loc_opt, cb
  
  genetic_entity_get : (opt, cb)->
    {
      url
      check_fn
    } = opt
    
    await @http_json_cont url, defer(err, res); return cb err if err
    {json, cont} = res
    
    # mini sanity check
    if !check_fn json
      return cb new Error "invalid block content"
    
    json.source = @url
    cb null, json
  
  # ###################################################################################################
  #    request
  # ###################################################################################################
  get_height : (opt, cb)->
    url = "#{@url}/height"
    await @http_json_cont_fast url, defer(err, res); return cb err if err
    cb null, res.json
  
  get_info : (opt, cb)->
    # / тоже выдает info, но это может поменяться
    url = "#{@url}/info"
    await @http_json_cont_fast url, defer(err, res); return cb err if err
    cb null, res.json
  
  get_block : (opt, cb)->
    if opt.height?
      {height} = opt
      
      loc_opt =
        url     : "#{@url}/block/height/#{height}"
        check_fn: (json)->
          json?.nonce?
      
      await @genetic_entity_get loc_opt, defer(err, json); return cb err if err
    else if opt.hash?
      {hash} = opt
      
      loc_opt =
        url     : "#{@url}/block/hash/#{hash}"
        check_fn: (json)->
          json?.nonce?
      
      await @genetic_entity_get loc_opt, defer(err, json); return cb err if err
    else
      perr "opt", opt
      return cb new Error "bad get_block request"
    
    # url = "#{loc_opt.url}/reward"
    # # await @http_json_cont_fast url, defer(err, res_status);
    # await @http_json_cont_fast url, defer(err, res_status);
    # # return cb err if err
    # if err
    #   perr "reward err", err.message, @url, opt.height or opt.hash
    #   json.reward = 0
    # else
    #   json.reward = res_status.json
    json.reward ?= 0
    
    cb null, json
  
  get_tx : (opt, cb)->
    {txid} = opt
    if !txid
      return cb new Error "get_tx requires txid"
    
    loc_opt =
      url : "#{@url}/tx/#{txid}"
      check_fn : (json)->
        json?.owner
    
    await @genetic_entity_get loc_opt, defer(err, json); return cb err if err
    
    url = "#{@url}/tx/#{txid}/status"
    await @http_json_cont_fast url, defer(err, res_status); return cb err if err
    json.status = res_status.json
    
    cb null, json
  
  get_peer_list : (opt, cb)->
    url = "#{@url}/peers"
    await @http_json_cont_fast url, defer(err, res); return cb err if err
    {json} = res
    
    if json.length == 0
      return cb new Error "empty peer list"
    
    json = json.filter (t)->
      return false if t.startsWith "127.0.0"
      return false if t.startsWith "192.168."
      return false if t.startsWith "172.17." # docker
      # TODO 10.0
      true
    
    cb null, json
  
  get_address : (opt, cb)->
    {address} = opt
    url = "#{@url}/wallet/#{address}/balance"
    await @http_cont_fast url, defer(err, balance); return cb err if err
    
    url = "#{@url}/wallet/#{address}/last_tx"
    await @http_cont_fast url, defer(err, last_tx); return cb err if err
    
    # NOTE это только outcoming
    url = "#{@url}/wallet/#{address}/txs"
    await @http_json_cont_fast url, defer(err, txs); return cb err if err
    
    url = "#{@url}/wallet/#{address}/deposits"
    await @http_json_cont_fast url, defer(err, deposits); return cb err if err
    
    cb null, {
      balance : balance.cont
      last_tx : last_tx.cont
      txs     : txs.json
      deposits: deposits.json
    }
  
  get_address_list : (opt, cb)->
    url = "#{@url}/wallet_list"
    await @http_json_cont url, defer(err, res_address_list); return cb err if err
    
    cb null, res_address_list.json

# ###################################################################################################
#    pipelines
# ###################################################################################################
class @Fallback_set_list_client
  client_list : []
  constructor:()->
    @client_list = []
  
  _generic_method : (method_name, opt, cb)->
    # set_method_name = method_name.replace "get_", "set_"
    err = null
    for client, idx in @client_list
      continue if !client[method_name]
      await client[method_name] opt, defer(err, res)
      continue if err
      # for send_idx in [idx-1 .. 0] by -1
      #   client = @client_list[send_idx]
      #   continue if !client[set_method_name]
      #   await client[set_method_name] opt, res, defer(err)
      #   perr err if err
      
      return cb null, res
    
    err ?= new Error "no client"
    cb err
  
  # ###################################################################################################
  #    impl
  # ###################################################################################################
  get_height      : (opt, cb)->@_generic_method "get_height",       opt, cb
  get_info        : (opt, cb)->@_generic_method "get_info",         opt, cb
  get_block       : (opt, cb)->@_generic_method "get_block",        opt, cb
  get_block_cache : (opt, cb)->@_generic_method "get_block_cache",  opt, cb
  get_block_cache_no_request : (opt, cb)->@_generic_method "get_block_cache_no_request",  opt, cb
  get_tx          : (opt, cb)->@_generic_method "get_tx",           opt, cb
  get_chunk_bson  : (opt, cb)->@_generic_method "get_chunk_bson",   opt, cb
  get_peer_list   : (opt, cb)->@_generic_method "get_peer_list",    opt, cb
  get_address     : (opt, cb)->@_generic_method "get_address",      opt, cb
  get_address_list: (opt, cb)->@_generic_method "get_address_list", opt, cb
  # post_block_my_ep: (opt, cb)->@_generic_method "post_block_my_ep", opt, cb
  get_pending_tx_list : (opt, cb)->@_generic_method "get_pending_tx_list",  opt, cb
  # ###################################################################################################
  #    special
  # ###################################################################################################
  # send all
  post_block_my_ep : (opt, cb)->
    can_throw_err = null
    res_list = []
    await
      for client in @client_list
        loc_cb = defer()
        do (client, loc_cb)->
          await client.post_block_my_ep opt, defer(err, res);
          if err
            perr err.message
            can_throw_err = err
            return loc_cb()
          
          res_list.push res
          loc_cb()
    
    if res_list.length == 0
      return cb can_throw_err
    
    cb null, res_list[0]
  
  # send all, pick best
  get_mine_data : (opt, cb)->
    can_throw_err = null
    res_list = []
    await
      for client in @client_list
        loc_cb = defer()
        do (client, loc_cb)->
          await client.get_mine_data opt, defer(err, res);
          if err
            perr err.message
            can_throw_err = err
            return loc_cb()
          
          res_list.push res
          loc_cb()
    
    if res_list.length == 0
      return cb can_throw_err
    
    # pick best res
    best = res_list[0]
    for res in res_list
      replace = false
      replace = true if best.state.block.height     < res.state.block.height
      replace = true if best.state.block.txs.length < res.state.block.txs.length
      best = res if replace
    
    cb null, best
  
@client = new module.Single_node_client config.arweave_node_url

@client_list = []
for url in config.arweave_node_url_list
  @client_list.push new module.Single_node_client url

@client_failover = new @Fallback_set_list_client
@client_failover.client_list = @client_list
