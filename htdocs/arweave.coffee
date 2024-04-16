window.block_time = 120

window.winston_to_ar = (t)->
  t / 1000000000000

window.winston_to_ar_format = (t)->
  winston_to_ar(t).to_format_float_string(6)

window.diff_to_avg_hash_count = (t)->
  max_bn = bn_shl BigInt(1), BigInt(256)
  value_bn = BigInt t
  rest = bn_sub max_bn, value_bn
  
  # my custom formula
  pass_hash_count_bn = bn_sub max_bn, value_bn
  full_hash_count_bn = max_bn
  avg_hash_count = +full_hash_count_bn.toString()/+pass_hash_count_bn.toString()

