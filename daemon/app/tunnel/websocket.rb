class Cuba
  def tunnel_handler
    lambda do |env|
      Async::WebSocket::Adapters::Rack.open(env, protocols: ['ws']) do |connection|
        condition = Async::Condition.new

        @tunnel_session = TunnelSession.new self, connection, 'RPC'

        self.class.enumerate_message(connection).each do |message|
          on_tunnel_message(connection, message: message)
        end
      rescue IOError
        # redis_context.close if redis_context
        # redis_client.close if redis_client
        # redis_context = nil
        # redis_client = nil
      rescue Protocol::WebSocket::ClosedError
        # redis_context.close if redis_context
        # redis_client.close if redis_client
        # redis_context = nil
        # redis_client = nil
      end or [403, {}, ['<p>Something happened.</p>']]
    end
  end

  def on_tunnel_message connection, message:
    Async do |task|
      @tunnel_session.on_tunnel_message task, message
    end
  end

end
