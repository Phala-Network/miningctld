SUBSTRATE_RPC_ENDPOINT = ENV['SUBSTRATE_RPC_ENDPOINT'] || 'http://phala-node:9944/'

class Substrate::Connection::RPC
  def initialize(conn)
    @conn = conn
  end

  def methods
    @conn.rpc_methods
  end

  def method_missing(method, *args)
    @conn.request method, *args
  end
end

class Substrate::Connection
  attr_reader :request_reactors
  attr_reader :current_request_id
  attr_reader :connection
  attr_reader :rpc
  attr_reader :runtime_version
  attr_reader :metadata
  attr_reader :rpc_methods

  def initialize
    @io_task = nil
    @connection = nil
    @current_request_id = 0
    @rpc = Substrate::Connection::RPC.new self
    @runtime_version = nil

    run!
  end

  def run!
    endpoint = Async::HTTP::Endpoint.parse(SUBSTRATE_RPC_ENDPOINT)
    Async do |task|
      @io_task = task
      $logger.info "Substrate RPC connecting: #{SUBSTRATE_RPC_ENDPOINT}"

      Async::WebSocket::Client.connect(endpoint) do |connection|
        connection.mask = SecureRandom.bytes(4)
        @connection = connection

        init_runtime

        enumerate_message.each do |message|
          on_tunnel_message message
        end
      rescue => e
        p e
      ensure
        $logger.info 'Substrate RPC disconnected.'
        exit -1
      end
    end
  end

  def init_runtime
    @io_task.async do
      react(rpc.state_getRuntimeVersion) {|message| @runtime_version = message }
      react(rpc.state_getMetadata) {|message| @metadata = Scale::Types::Metadata.decode(Scale::Bytes.new(message)) }
      react(rpc.rpc_methods) {|message| @rpc_methods = message["methods"] }
      rpc.chain_subscribeFinalisedHeads

      @spec_version = @runtime_version["specVersion"]
      Scale::TypeRegistry.instance.spec_version = @spec_version
      Scale::TypeRegistry.instance.metadata = @metadata.value
    end
  end

  def request(method, *params)
    @current_request_id += 1

    request_id = @current_request_id
    task = @io_task.async do
      payload = {
        "id" => @current_request_id,
        "jsonrpc" => "2.0",
        "method" => method,
        "params" => params
      }
      $logger.info "[Substrate RPC]Sending: #{payload}"
      @connection.write payload.to_json
      @connection.flush
    rescue => exception
      $logger.error exception
    end

    request_id
  end

  def react(request_id)
    reactor_name = "@reactor_#{request_id}".to_sym
    reactor = Async::Condition.new
    self.instance_variable_set reactor_name, reactor

    if block_given?
      result = reactor.wait
      if result["result"]
        yield(result["result"])
      else
        raise result
      end
    else
      reactor
    end
  end

  def enumerate_message
    Enumerator.new do |yielder|
      while (message = @connection.read)
        yielder << message
      end
    end
  end

  def on_tunnel_message(buffer)
    @io_task.async do |task|
      message = JSON.parse(buffer)
      $logger.info "[Substrate RPC]Receiving: #{message}"
      reactor_name = "@reactor_#{message["id"]}".to_sym
      reactor = self.instance_variable_get reactor_name
      if reactor
        reactor.signal message
      end
    end
  end

end
