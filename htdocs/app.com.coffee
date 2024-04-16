module.exports =
  render : ()->
    Router_multi {
      # subroute_delimiter: "/"
      # route_delimiter   : "|" # unused
      render : (hash)=>
        switch path = hash[""]?.path or ""
          when ""
            Page_dashboard {}
          when "address_list"
            Page_address_list {}
          when "peer_list"
            Page_peer_list {}
          else
            if reg_ret = /^block\/(\d+)$/.exec path
              [_, height] = reg_ret
              Page_block {height:+height}
            else if reg_ret = /^block\/(.+)$/.exec path
              [_, hash] = reg_ret
              Page_block {hash}
            else if reg_ret = /^tx\/(.+)$/.exec path
              [_, txid] = reg_ret
              Page_tx {txid}
            # else if reg_ret = /^address\/(.+)$/.exec path
              # [_, address] = reg_ret
              # Page_address {address}
            else if reg_ret = /^calculator\/?$/.exec path
              Page_calculator_272 {query_hash:{}}
            else if reg_ret = /^calculator_272\/?$/.exec path
              Page_calculator_272 {query_hash:{}}
            else if reg_ret = /^calculator\/(.*)$/.exec path
              [_, query] = reg_ret
              query_pair_list = query.split("&")
              query_hash = {}
              for query_pair in query_pair_list
                [k,v] = query_pair.split("=")
                query_hash[k] = decodeURIComponent v
              Page_calculator_272 {query_hash}
            else
              perr "bad route", hash
              route_go ""
              div ""
    }
