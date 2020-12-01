def define_error(name:, msg:, code:)
  Object.const_set(name, Class.new(StandardError) { |c|
    to_proto = proc { Proto::Error.new(
      status: code,
      message: msg,
      name: name
    )}
    c.define_method :code, proc { code }
    c.define_method :msg, proc { msg }
    c.define_method :to_proto, to_proto
    c.define_singleton_method :to_proto, to_proto
  })
end

define_error(
  name: 'AppSomeError',
  msg: 'You should never see this in production.',
  code: :SOME_ERROR
)

define_error(
  name: 'AppServerError',
  msg: 'Server Error.',
  code: :SERVER_ERROR
)

define_error(
  name: 'AppNoHandlerError',
  msg: 'Handler invalid or not implemented.',
  code: :NOT_FOUND_ERROR
)

define_error(
  name: 'InvalidRequestError',
  msg: 'Invalid Request.',
  code: :BAD_REQUEST_ERROR
)

define_error(
  name: 'RateLimitReachedError',
  msg: 'Rate limit reached.',
  code: :BAD_REQUEST_ERROR
)

define_error(
  name: 'AuthenticationError',
  msg: 'Authentication Error.',
  code: :UNAUTHORIZED
)