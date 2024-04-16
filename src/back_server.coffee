#!/usr/bin/env iced
### !pragma coverage-skip-block ###
fs      = require "fs"
os      = require "os"
ws      = require "ws"
{URL}   = require "url"

express = require "express"

require "fy"

config  = require "./config"
if config.http_query_array_support
  qs = require "qs"

# ###################################################################################################
#    watch
# ###################################################################################################
if config.watch
  do ()->
    chokidar = require "chokidar"
    watcher = chokidar.watch "src"
    await watcher.on "ready", defer()
    timeout = null
    handler = (path)->
      clearTimeout timeout if timeout
      timeout = setTimeout ()->
        puts "node file changed", path
        process.exit()
      , 100
    
    watcher.on "add",    handler
    watcher.on "change", handler
    watcher.on "unlink", handler

# ###################################################################################################
#    endpoints collect
# ###################################################################################################
endpoint_file_list = fs.readdirSync "src/endpoint"
endpoint_hash = {}
for file in endpoint_file_list
  mod = require "./endpoint/#{file}"
  obj_set endpoint_hash, mod

endpoint_file_list = fs.readdirSync "src/http_only_endpoint"
http_endpoint_hash = {}
for file in endpoint_file_list
  mod = require "./http_only_endpoint/#{file}"
  obj_set http_endpoint_hash, mod

# ###################################################################################################
#    http server
# ###################################################################################################
app = express()

# app.use require("helmet")()
# app.use express.static "./static", dotfiles: "allow"

app.use (req, res)->
  url = new URL req.url, "http://domain/"
  switch_key = url.pathname.substr(1)
  
  if !fn = http_endpoint_hash[switch_key] ? endpoint_hash[switch_key]
    return res.end JSON.stringify
      switch: switch_key
      error :"bad endpoint"
  
  # array support
  if config.http_query_array_support
    opt = qs.parse(url.search.substr 1)
  else
    opt = {}
    url.searchParams.forEach (v,k)->
      opt[k] = v
  
  fn opt, (err, loc_res, skip)->
    if err
      perr err if config.debug
      return res.end JSON.stringify {
        switch  : switch_key
        error   : err.message
      }
    if !skip
      res_json = Object.assign {switch: switch_key}, loc_res
      res.end JSON.stringify res_json, null, 2
    return
  , req, res
  
app.listen config.back_http_port

# ###################################################################################################
#    ws server
# ###################################################################################################
connection_uid = 1 # uid 0 == http persistant template
ws_handler = (connection)->
  connection.__uid = connection_uid++
  connection.on "message", (msg)->
    try
      data = JSON.parse msg
    catch err
      perr err
      return
    
    switch_key = data.switch
    if !fn = endpoint_hash[switch_key]
      return connection.send JSON.stringify
        switch: switch_key
        error :"bad endpoint"
    
    fn data, (err, res)->
      if err
        perr err
        return connection.send JSON.stringify
          switch: switch_key
          request_uid : data.request_uid
          error : err.message
      
      res = Object.assign {
        switch      : switch_key
        request_uid : data.request_uid
      }, res
      return connection.send JSON.stringify res
    , null, null, (msg)->
      connection.send JSON.stringify msg
    , connection

wss = new ws.Server port:config.back_ws_port
wss.on "connection", ws_handler

# ###################################################################################################

puts "[INFO] listen:"
for k,list of os.networkInterfaces()
  for v in list
    continue if v.family != "IPv4"
    continue if v.address == "127.0.0.1"
    puts "[INFO]   http://#{v.address}:#{config.back_http_port}"
    puts "[INFO]     ws://#{v.address}:#{config.back_ws_port}"
    puts "[INFO]"
