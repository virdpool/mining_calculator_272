window.iced = exports = {}
C =
  k : "__iced_k"
  k_noop : "__iced_k_noop"
  param : "__iced_p_"
  ns: "iced"
  runtime : "runtime"
  Deferrals : "Deferrals"
  deferrals : "__iced_deferrals"
  fulfill : "_fulfill"
  b_while : "_break"
  t_while : "_while"
  c_while : "_continue"
  n_while : "_next"
  n_arg   : "__iced_next_arg"
  defer_method : "defer"
  slot : "__slot"
  assign_fn : "assign_fn"
  autocb : "autocb"
  retslot : "ret"
  trace : "__iced_trace"
  passed_deferral : "__iced_passed_deferral"
  findDeferral : "findDeferral"
  lineno : "lineno"
  parent : "parent"
  filename : "filename"
  funcname : "funcname"
  catchExceptions : 'catchExceptions'
  runtime_modes : [ "node", "inline", "window", "none", "browserify", "interp" ]
  trampoline : "trampoline"
  context : "context"
  defer_arg : "__iced_defer_"  

#===============================================================

make_defer_return = (obj, defer_args, id, trace_template, multi) ->

  trace = {}
  for k,v of trace_template
    trace[k] = v
  trace[C.lineno] = defer_args?[C.lineno]

  ret = (inner_args...) ->
    defer_args?.assign_fn?.apply(null, inner_args)
    if obj
      o = obj
      obj = null unless multi
      o._fulfill id, trace
    else
      warn "overused deferral at #{_trace_to_string trace}"

  ret[C.trace] = trace

  ret

#===============================================================

#### Tick Counter
#  count off every mod processor ticks
#
__c = 0

tick_counter = (mod) ->
  __c++
  if (__c % mod) == 0
    __c = 0
    true
  else
    false

#===============================================================

#### Trace management and debugging
#
__active_trace = null

_trace_to_string = (tr) ->
  fn = tr[C.funcname] || "<anonymous>"
  "#{fn} (#{tr[C.filename]}:#{tr[C.lineno] + 1})"

warn = (m) ->
  console?.error "ICED warning: #{m}"

#===============================================================

####
#
# trampoline --- make a call to the next continuation...
#   we can either do this directly, or every 500 ticks, from the
#   main loop (so we don't overwhelm ourselves for stack space)..
#
exports.trampoline = trampoline = (fn) ->
  if not tick_counter 500
    fn()
  else if process?.nextTick?
    process.nextTick fn
  else
    setTimeout fn

#===============================================================

#### Deferrals
#
#   A collection of Deferrals; this is a better version than the one
#   that's inline; it allows for iced tracing
#

exports.Deferrals = class Deferrals

  #----------

  constructor: (k, @trace) ->
    @continuation = k
    @count = 1
    @ret = null

  #----------

  _call : (trace) ->
    if @continuation
      __active_trace = trace
      c = @continuation
      @continuation = null
      c @ret
    else
      warn "Entered dead await at #{_trace_to_string trace}"

  #----------

  _fulfill : (id, trace) ->
    if --@count > 0
      # noop
    else
      trampoline ( () => @_call trace )

  #----------

  defer : (args) ->
    @count++
    self = this
    return make_defer_return self, args, null, @trace

#===============================================================

#### findDeferral
#
# Search an argument vector for a deferral-generated callback

exports.findDeferral = findDeferral = (args) ->
  for a in args
    return a if a?[C.trace]
  null

#===============================================================

#### Rendezvous
#
# More flexible runtime behavior, can wait for the first deferral
# to fire, rather than just the last.

exports.Rendezvous = class Rendezvous
  constructor: ->
    @completed = []
    @waiters = []
    @defer_id = 0

  # RvId -- A helper class the allows deferalls to take on an ID
  # when used with Rendezvous
  class RvId
    constructor: (@rv,@id,@multi)->
    defer: (defer_args) ->
      @rv._defer_with_id @id, defer_args, @multi

  # Public interface
  #
  # The public interface has 3 methods --- wait, defer and id
  #
  wait: (cb) ->
    if @completed.length
      x = @completed.shift()
      cb(x)
    else
      @waiters.push cb

  defer: (defer_args) ->
    id = @defer_id++
    @_defer_with_id id, defer_args

  # id -- assign an ID to a deferral, and also toggle the multi
  # bit on the deferral.  By default, this bit is off.
  id: (i, multi) ->
    multi = !!multi
    new RvId(this, i, multi)

  # Private Interface

  _fulfill: (id, trace) ->
    if @waiters.length
      cb = @waiters.shift()
      cb id
    else
      @completed.push id

  _defer_with_id: (id, defer_args, multi) ->
    @count++
    make_defer_return this, defer_args, id, {}, multi

#==========================================================================

#### stackWalk
#
# Follow an iced-generated stack walk from the active trace
# up as far as we can. Output a vector of stack frames.
#
exports.stackWalk = stackWalk = (cb) ->
  ret = []
  tr = if cb then cb[C.trace] else __active_trace
  while tr
    line = "   at #{_trace_to_string tr}"
    ret.push line
    tr = tr?[C.parent]?[C.trace]
  ret

#==========================================================================

#### exceptionHandler
#
# An exception handler that triggers the above iced stack walk
#

exports.exceptionHandler = exceptionHandler = (err, logger) ->
  logger = console.error unless logger
  logger err.stack
  stack = stackWalk()
  if stack.length
    logger "Iced 'stack' trace (w/ real line numbers):"
    logger stack.join "\n"

#==========================================================================

#### catchExceptions
#
# Catch all uncaught exceptions with the iced exception handler.
# As mentioned here:
#
#    http://debuggable.com/posts/node-js-dealing-with-uncaught-exceptions:4c933d54-1428-443c-928d-4e1ecbdd56cb
#
# It's good idea to kill the service at this point, since state
# is probably horked. See his examples for more explanations.
#
exports.catchExceptions = (logger) ->
  process?.on 'uncaughtException', (err) ->
    exceptionHandler err, logger
    process.exit 1

#==========================================================================
  
  
#===============================================================

#
# icedlib
#
#   This class contains non-essential but convenient runtime libraries
#   for iced programs
#

#===============================================================

# The `timeout` connector, which allows us to compose timeouts with
# existing event-based calls
#
_timeout = (cb, t, res, tmp) ->
  rv = new iced.Rendezvous
  tmp[0] = rv.id(true).defer(arr...)
  setTimeout rv.id(false).defer(), t
  await rv.wait defer which
  res[0] = which if res
  cb.apply(null, arr)

exports.timeout = (cb, t, res) ->
  tmp = []
  _timeout cb, t, res, tmp
  tmp[0]

#===============================================================

#
# The 'and' connector, that allows you to check only once that
# all operations with a parallel `await` worked...
#
_iand = (cb, res, tmp) ->
  await
    tmp[0] = defer ok
  res[0] = false unless ok
  cb()

# this function takes as input two values: a callback, and a place
# to store a result. It returns a new callback.
exports.iand = (cb, res) ->
  tmp = []
  _iand cb, res, tmp
  tmp[0]

#===============================================================

#
# The 'or' connector, that allows you to check only once that
# one of several operations in a parallel `await` worked
#
_ior = (cb, res, tmp) ->
  await
    tmp[0] = defer ok
  res[0] = true if ok
  cb()

exports.ior = (cb, res) ->
  tmp = []
  _ior cb, res, tmp
  tmp[0]

#===============================================================

####
#
# Pipeliner -- a class for firing a follow of network calls in a pipelined
#   fashion, so that only so many of them are outstanding at once.
#
exports.Pipeliner = class Pipeliner

  #-------------------------------

  constructor : (window, delay) ->
    @window = window || 1
    @delay = delay || 0
    @queue = []
    @n_out = 0
    @cb = null

    # This is a hack to work with the desugaring of
    # 'defer' output by the coffee compiler. Same as in rendezvous
    @[C.deferrals] = this

    # Rebind "defer" to "_defer"; We can't do this directly since the
    # compiler would pick it up
    @["defer"] = @_defer

  #-------------------------------

  # Call this to wait in a queue until there is room in the window
  waitInQueue : (cb) ->

    # Wait until there is room in the window.
    while @n_out >= @window
      await (@cb = defer())

    # Lanuch a computation, so mark that there's one more
    # guy outstanding.
    @n_out++

    # Delay if that was asked for...
    if @delay
      await setTimeout defer(), @delay

    cb()

  #-------------------------------

  # Helper for this._defer, seen below..
  __defer : (out, deferArgs) ->

    # Make a callback that this.defer can return.
    # This callback might have to fill in slots when its
    # fulfilled, so that's why we need to wrap the output
    # of defer() in an anonymous wrapper.
    await
      voidCb = defer()
      out[0] = (args...) ->
        deferArgs.assign_fn?.apply null, args
        voidCb()

    # There is now one fewer outstanding computation.
    @n_out--

    # If some is waiting in waitInQueue above, then now is the
    # time to release him. Use "race-free" callback technique.
    if @cb
      tmp = @cb
      @cb = null
      tmp()

  #-------------------------------

  # This function, Pipeliner._defer, has to return a
  # callback to its caller.  It does this with the same trick above.
  # The helper function _defer() does the heavy lifting, returning
  # its callback to us as the first slot in tmp[0].
  _defer : (deferArgs) ->
    tmp = []
    @__defer tmp, deferArgs
    tmp[0]

  # flush everything left in the pipe
  flush : (autocb) ->
    while @n_out
      await (@cb = defer())

#===============================================================  