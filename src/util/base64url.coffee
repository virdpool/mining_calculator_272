buf_pool = require "./buf_pool"

@encode = (t)->
  res = t.toString "base64"
  
  # https://github.com/brianloveswords/base64url/blob/master/src/base64url.ts
  res = res.replace(`/=/g`, "")
  res = res.replace(/\+/g, "-")
  res = res.replace(/\//g, "_")
  res

@decode = (t)->
  Buffer.from t, "base64"

# важно, нельзя сохранять такой буфер
decode_mem_safe_buf = null
@decode_mem_safe = (t)->
  decode_mem_safe_buf ?= Buffer.alloc 10*1024*1024
  size = decode_mem_safe_buf.write t, 0, undefined, "base64"
  decode_mem_safe_buf.slice(0, size)

@decode_buf_pool = (t, size)->
  ret = buf_pool.alloc size
  size = ret.write t, 0, undefined, "base64"
  ret
