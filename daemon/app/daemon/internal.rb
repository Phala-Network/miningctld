INTERNAL_TUNNEL_ENDPOINT = ENV['INTERNAL_TUNNEL_ENDPOINT'] || 'http://127.0.0.1:9292/tunnel'

class Daemon::Internal
  def initialize parent
    @parent = parent
    @io_task = nil

    @connection = nil
    @tunnel_session = nil
  end

  def run!
    @parent.io_task.async do |task|
      @io_task = task
      
      endpoint = Async::HTTP::Endpoint.parse(INTERNAL_TUNNEL_ENDPOINT)

      Async::WebSocket::Client.connect(endpoint) do |connection|
        @connection = connection
        @tunnel_session = TunnelSession.new self, connection, 'Daemon', :INTERNAL, :INTERNAL
        @tunnel_session.public_key = @parent.running_config.keypair.public_key
        @tunnel_session.private_key = @parent.running_config.keypair.private_key

        @tunnel_session.send_keepalive @io_task

        enumerate_message.each do |message|
          on_tunnel_message(@io_task, message)
        end
      ensure
        $logger.info 'Internal tunnel disconnected.'
      end
    end
  end

  def enumerate_message
    @parent.app.enumerate_message(@connection)
  end

  def on_tunnel_message parent_task, buffer
    parent_task.async do |task|
      @tunnel_session.on_tunnel_message task, buffer
    end
  end

  # todo: watchdog
end
