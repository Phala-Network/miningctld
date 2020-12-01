class ProvisioningCode < Ohm::Model
  include OhmModelBase

  attribute :status, Type::Symbol # [:usable, :used, :revoked]
  attribute :registered_daemon, Type::Integer
  reference :keypair, :Keypair

  unique :registered_daemon
  index :status
  index :registered_daemon
  index :keypair

  def daemon
    RegisteredDaemon.find(registered_daemon)
  end

  def revoke
    update :status => :revoked
  end

  def self.provision(body)
    req = Proto::GetCertRequest.decode body

    record = self.find(uuid: req.code).first
    return nil if !record || record.status != :usable

    cert = record.keypair.certificate.to_pem
    ec = OpenSSL::PKey::EC.generate 'prime256v1'
    key = Crypto.compute_ecdh_key ec, req.temp_public_key

    res = Proto::GetCertResponse.new(
      encrypted_cert: Crypto.aes_encrypt(key, req.nonce, cert),
      encrypted_key: Crypto.aes_encrypt(key, req.nonce, record.keypair.private_key.to_pem),
      temp_public_key: ec.public_key.to_bn.to_s(2)
    )

    record.update :status => :used
    record.daemon.provisioned!
    record.daemon.save!

    Proto::GetCertResponse.encode res
  end
end
