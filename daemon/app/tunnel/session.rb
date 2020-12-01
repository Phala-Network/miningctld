class TunnelSession
  attr_writer :public_key
  attr_writer :private_key

  attr_writer :aes_key
  attr_writer :aes_iv

  attr_writer :encrypt_mode

  attr_reader :env
  attr_reader :connection
  attr_reader :io_task

  def initialize(env, connection, name, source = nil, target = nil)
    @connection = connection
    @env = env
    @name = name
    @io_task = nil

    @source = source
    @target = target

    @encrypt_mode = :plain

    @public_key = nil
    @private_key = nil

    @aes_key = nil
    @aes_iv = nil
    @req_ec = nil

    @confirmed = false

    @daemon = nil
  end

  def check_source(message)
    unless @source && @target
      @source = message.target
      @target = message.source

      if @source === :INTERNAL
        @public_key = running_config.keypair.public_key
        @private_key = running_config.keypair.private_key
      end

      return message
    end

    if @confirmed && !(@source === message.target && @target === message.source)
      $logger.warn "Message source mismatch, ignoring: #{@source}, #{@target}"

      return nil
    end

    message
  end

  def on_tunnel_message(task, message)
    @io_task = task

    begin
      related_refs = nil
      throw InvalidRequestError if !message

      $logger.debug "#{@name}:#{@source || 'UNSET'} receiving..."
      message = decode message
      if message
        related_refs = [message.ref]
      
        throw AppNoHandlerError if !(respond_to? message.handler)
  
        response = self.send(message.handler, message)
  
        if response
          @connection.write encode(related_refs: related_refs, **response)
          @connection.flush
        end

        if @confirmed && @encrypt_mode === :plain
          if @aes_iv && @aes_key
            @encrypt_mode = :aes
          elsif @private_key && @public_key
            @encrypt_mode = :rsa
          end
        end
      end
    rescue => exception
      error_proto = nil

      if exception.instance_of? Google::Protobuf::ParseError
        error_proto = InvalidRequestError.to_proto
      elsif (
        exception.instance_of?(UncaughtThrowError) &&
        exception.tag &&
        exception.tag.respond_to?(:to_proto)
      )
        error_proto = exception.tag.to_proto
      elsif exception.respond_to?(:to_proto)
        error_proto = exception.to_proto
      else
        $logger.error exception
      end

      error_proto ||= AppServerError.to_proto
      @connection.write encode(
        related_refs: related_refs,
        error: error_proto
      )
      @connection.flush
    end
  end

  def handle_error message
    nil
  end

  def handle_keepalive message
    unless @confirmed
      @confirmed = true
    end

    return nil if message.payload!.is_responder
    {
      keepalive: {
        is_responder: true
      }
    }
  end

  def send_keepalive parent_task
    parent_task.async do |task|
      $logger.info "Starting sending keepalive from #{@source} to #{@target}..." 

      while true
        data = encode(
          source: @source,
          target: @target,
          ref: SecureRandom.uuid,
          keepalive: {
            is_responder: false
          }
        )
        @connection.write(data)
        @connection.flush
        task.sleep 10
      end
    end
  end

  def encode **args
    self.send "#{@encrypt_mode.to_s}_encode".to_sym, **args
  end

  def decode buffer
    self.send "#{@encrypt_mode.to_s}_decode".to_sym, buffer
  end

  def plain_encode **args
    Proto.plain_encode(
      source: @source,
      target: @target,
      ref: SecureRandom.uuid,
      created_at: Time.now,
      **args
    )
  end

  def plain_decode buffer
    check_source (Proto.plain_or_rsa_decode buffer, private_key: @private_key)
  end

  def aes_encode **args
    Proto.aes_encode(
      key: @aes_key,
      iv: @aes_iv,
      source: @source,
      target: @target,
      ref: SecureRandom.uuid,
      created_at: Time.now,
      **args
    )
  end

  def aes_decode buffer
    check_source (Proto.aes_decode buffer, key: @aes_key, iv: @aes_iv)
  end

  def rsa_encode **args
    Proto.rsa_encode(
      public_key: @public_key,
      source: @source,
      target: @target,
      ref: SecureRandom.uuid,
      created_at: Time.now,
      **args
    )
  end

  def rsa_decode buffer
    check_source (Proto.plain_or_rsa_decode buffer, private_key: @private_key)
  end

  def running_config
    DaemonConfig.active_config
  end

  def role_instance
    @env.role_instance
  end
end
