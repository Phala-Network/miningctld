namespace :daemon do
  desc 'Init as a controlled daemon'
  task :init do
    code = ENV['CODE']
    endpoint = "#{ENV['ENDPOINT']}/provision"
    nonce = SecureRandom.random_bytes 16

    ec = OpenSSL::PKey::EC.generate 'prime256v1'

    req = Proto::GetCertRequest.new(
      nonce: nonce,
      code: code,
      temp_public_key: ec.public_key.to_bn.to_s(2)
    )
    req = Proto::GetCertRequest.encode req

    res = Faraday.post endpoint do |r|
      r.body = req
    end

    raise res.inspect unless res.status === 200
    res = Proto::GetCertResponse.decode res.body

    key = Crypto.compute_ecdh_key ec, res.temp_public_key

    cert = OpenSSL::X509::Certificate.new Crypto.aes_decrypt(key, nonce, res.encrypted_cert)
    private_key = OpenSSL::PKey::RSA.new Crypto.aes_decrypt(key, nonce, res.encrypted_key)

    crypto_cert = Crypto::Certificate.new private_key, cert
    keypair = crypto_cert.write_keypair

    DaemonConfig.create(
      controlled: true,
      endpoint: ENV['ENDPOINT'],
      keypair: keypair,
      role: :unset
    )
  end
end

  
namespace :controller do
  desc 'Init as a controlled daemon'
  task :init do
    phrase = SecureRandom.hex 16
    cert = Crypto.generate_ca_cert
    daemon_cert = cert.generate_cert

    account = Account.generate

    controller_config = ControllerConfig.create(
      ca_pass_phrase: phrase,
      ca_keypair: cert.write_keypair,
      account: account
    )

    DaemonConfig.create(
      controlled: false,
      keypair: daemon_cert.write_keypair,
      role: :controller,
      controller_config: controller_config
    )

    account.print
  end

  desc 'Register a new worker.'
  task :register_worker do
    daemon = RegisteredDaemon.generate :worker, ENV['DESC']
    account = Account.generate
    daemon.account = account.to_hash
    daemon.save!

    account.top_up
    account.bind_stash
    account.set_commission

    puts daemon.provisioning_code
  end

  desc 'Register a new bridge.'
  task :register_bridge do
    daemon = RegisteredDaemon.generate :bridge, ENV['DESC']
    puts daemon.provisioning_code
  end

  desc 'Register a new controller.'
  task :register_controller do
    daemon = RegisteredDaemon.generate :controller, ENV['DESC']
    puts daemon.provisioning_code
  end
end
