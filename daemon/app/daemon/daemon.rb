class Daemon
  attr_reader :app
  attr_reader :status
  attr_reader :running_config
  attr_reader :io_task
  attr_accessor :role_instance
  attr_reader :external_io_task
  attr_reader :external_tunnel_session

  def initialize app
    @app = app
    @running_config = DaemonConfig.active_config
    
    @io_task = nil

    @internal_tunnel = nil

    @external_io_task = nil
    @external_tunnel_connection = nil
    @external_tunnel_session = nil

    @role_instance = nil
  end

  def run!
    unless @running_config
      $logger.error 'Not initialized, exiting...'
      exit -1
    end
    
    task = Async do |task|
      @io_task = task
      @internal_tunnel = Daemon::Internal.new self
      @internal_tunnel.run!

      setup_controlled
    end

    task.wait
  end

  def reset
    @app.instance_variable_set :@daemon, (Daemon.new @app)
  end

  def setup_role
    @role_instance = role_class.new self
  end

  def setup_controlled
    unless @running_config.controlled
      $logger.info 'Started uncontrolled mode.'
      return setup_role
    end

    $logger.info "Started controlled mode, trying to request provisioning from #{external_endpoint}"
    
    @io_task.async do |task|
      @external_io_task = task

      endpoint = Async::HTTP::Endpoint.parse(external_endpoint)

      Async::WebSocket::Client.connect(endpoint) do |connection|
        @external_tunnel_connection = connection
        @external_tunnel_session = TunnelSession.new self, connection, 'Daemon', nil, nil

        @external_tunnel_session.request_provisioning @external_io_task
 
        external_tunnel_enumerate_message.each do |message|
          on_external_tunnel_message(@external_io_task, message)
        end
      rescue => err
        $logger.error err
      ensure
        $logger.info 'External tunnel disconnected.'
        exit 0
      end
    end
  end

  def external_tunnel_enumerate_message
    @app.enumerate_message(@external_tunnel_connection)
  end

  def on_external_tunnel_message parent_task, buffer
    parent_task.async do |task|
      @external_tunnel_session.on_tunnel_message task, buffer
    end
  end

  def publish_command
  end

  def external_endpoint
    "#{@running_config.endpoint}/tunnel"
  end

  def role_class
    ret = self.class.const_get @running_config.role.to_s.capitalize
    unless ret
      raise RuntimeError "Invalid daemon role!"
    end
    ret
  end
end
