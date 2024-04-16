module = @
require "fy"
require("events").EventEmitter.defaultMaxListeners = Infinity
argv = require("minimist")(process.argv.slice(2))
config = require("dotenv-flow").config().parsed or {}
for k,v of argv
  config[k.toUpperCase()] = v

bool = (name, default_value = "0", config_name = name.toUpperCase())->
  module[name] = !!+(config[config_name] ? default_value)

int  = (name, default_value = "0", config_name = name.toUpperCase())->
  module[name] = +(config[config_name] ? default_value)

str  = (name, default_value = "", config_name = name.toUpperCase())->
  module[name] = config[config_name] ? default_value

str_list  = (name, default_value = "", config_name = name.toUpperCase())->
  module[name] = (config[config_name] ? default_value).split ","

# ###################################################################################################
#    common
# ###################################################################################################
bool "debug"
bool "watch"

# ###################################################################################################
#    front
# ###################################################################################################
str  "front_title", "Arweave block explorer"
int  "front_http_port", "9900"
int  "front_ws_port",   "19900"
bool "http_query_array_support"

# ###################################################################################################
#    backend
# ###################################################################################################
int  "back_http_port",  "9100"
int  "back_ws_port",    "9101"

# ###################################################################################################
#    arweave
# ###################################################################################################
# ВАЖНО, для mainnet очень желательно несколько нод
str  "arweave_node_url", "http://virdpool.com:2984"
str_list "arweave_node_url_list", "ARWEAVE_NODE_URL_LIST"

# ###################################################################################################
#    http_client
# ###################################################################################################
int  "arweave_http_client_err_cache_ts", "10000"
int  "arweave_http_client_429_ts", "60000"
int  "arweave_http_client_long_http_timeout", "10000"
int  "arweave_http_client_short_http_timeout", "6000"

# ###################################################################################################
#    arweave daemon
# ###################################################################################################
int  "height_poll_ts", "1000"
int  "last_block_list_count", "100"
