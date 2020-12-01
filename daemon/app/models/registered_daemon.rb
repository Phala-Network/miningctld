class RegisteredDaemon < ActiveRecord::Base
  enum management_status: [:idle, :provisioned, :disabled, :deleted]
  enum role: [:unset, :worker, :bridge, :controller]

  def keypair
    Keypair.find(uuid: uuid).first
  end

  def certificate
    keypair.to_crypto_cert
  end

  def provisioning_code
    return nil if self.unset?
    return nil unless self.idle?
    
    code = ProvisioningCode.find(
      registered_daemon: id,
      status: :usable
    ).first

    return code.uuid if !!code

    code = ProvisioningCode.create(
      status: :usable,
      registered_daemon: id, 
      keypair: keypair
    )
    code.uuid
  end

  def worker_states
    return nil unless self.worker?
    
    state = WorkerStates.find(registered_daemon: id).first

    return state if !!state

    WorkerStates.create(
      registered_daemon: id,
      status: :UNKNOWN,
      pending_set_intention: false
    )
  end

  def account
    Account[super["id"]]
  end

  def self.generate role, description
    cert = running_config.controller_config.ca_keypair.to_crypto_cert.generate_cert
    daemon = self.create(
      hash_id: cert.hash_id,
      uuid: cert.uuid,
      management_status: :idle,
      role: role,
      description: description || ''
    )

    cert.write_keypair
    daemon
  end
end
