class TunnelSession
  def request_provisioning(task)
    @io_task = task
    @req_ec = OpenSSL::PKey::EC.generate 'prime256v1'
    @aes_iv = SecureRandom.random_bytes 16

    task.async do |subtask|
      $logger.info "Exchanging transport key using certificate..."

      data = encode(
        source: @source,
        target: @target,
        ref: SecureRandom.uuid,
        request_provisioning: {
          cert: running_config.keypair.certificate.to_pem,
          temp_public_key: @req_ec.public_key.to_bn.to_s(2),
          nonce: @aes_iv
        }
      )
      @connection.write(data)
      @connection.flush
    end
  end

  def handle_request_provisioning(message)
    cert = OpenSSL::X509::Certificate.new message.payload!.cert
    daemon_uuid = cert.uuid

    $logger.info "Exchanging transport key for daemon #{daemon_uuid}"

    raise AuthenticationError unless cert.verify running_config.controller_config.ca_keypair.public_key

    daemon = RegisteredDaemon.find_by(uuid: daemon_uuid)
    raise AuthenticationError if !daemon
    @daemon = daemon

    keypair = Keypair.find(uuid: daemon_uuid).first
    raise AuthenticationError if !daemon
    raise AuthenticationError unless cert.hash_id === keypair.hash_id && cert.hash_id === daemon.hash_id

    @req_ec = OpenSSL::PKey::EC.generate 'prime256v1'
    @aes_iv = message.payload!.nonce
    @aes_key = Crypto.compute_ecdh_key @req_ec, message.payload!.temp_public_key

    @source = :CONTROLLER
    @target = daemon.role.to_s.upcase.to_sym

    info = self.send "set_#{daemon.role.to_s}_info".to_sym, Proto::ShouldProvision::Info.new(
      controller_daemon_info: {
        uuid: running_config.keypair.certificate.uuid,
        role: @source
      },
      daemon_info: {
        uuid: daemon_uuid,
        role: @target
      }
    )
    info = Proto::ShouldProvision::Info.encode info
    info = Crypto.aes_encrypt @aes_key, @aes_iv, info

    {
      should_provision: {
        temp_public_key: @req_ec.public_key.to_bn.to_s(2),
        encrypted_info: info
      }
    }
  end

  def handle_should_provision(message)
    @source = message.target
    @target = message.source

    @aes_key = Crypto.compute_ecdh_key @req_ec, message.payload!.temp_public_key

    info = Crypto.aes_decrypt @aes_key, @aes_iv, message.payload!.encrypted_info
    info = Proto::ShouldProvision::Info.decode info

    $logger.info "Received provisioning information." 
    $logger.info info.inspect

    @env.running_config.apply_provision_info info

    unless @env.role_instance
      @env.setup_role
    end

    send_keepalive @io_task

    nil
  end

  def set_worker_info(info)
    info.daemon_info.worker_info = Proto::WorkerInfo.new
    info
  end

  def set_controller_info(info)
    daemon = RegisteredDaemon.find_by(uuid: info.daemon_info.uuid)

    info.daemon_info.controller_info = Proto::ControllerInfo.new({
      status: :IDLE,
      description: daemon.description,
      account: daemon.account.to_worker_account.to_proto
    })
    info
  end

  def set_bridge_info(info)
    info.daemon_info.bridge_info = Proto::BridgeInfo.new
    info
  end
end
