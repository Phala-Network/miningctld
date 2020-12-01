require 'openssl'

CIPHER = ENV['CIPHER'] || 'AES-256-CBC'
RSA_KEY_SIZE = ENV['RSA_KEY_SIZE'].to_i || 4096
CA_CERT_NAME = ENV['CA_CERT_NAME'] || '/CN=Mining Controller CA/DC=phala'
DAEMON_CERT_NAME = ENV['DAEMON_CERT_NAME'] || '/CN=Mining Controller Daemon/DC=phala'

class OpenSSL::X509::Certificate
  def uuid
    (subject.to_a.find {|i| i[0] === 'UID'})[1]
  end

  def hash_id
    Digest::SHA256.hexdigest "#{uuid}#{subject.hash}"
  end
end

module Crypto
  def generate_ca_cert
    cert = cert!
    private_key = key!
    uuid = uuid!

    subject = OpenSSL::X509::Name.parse "/UID=#{uuid}#{CA_CERT_NAME}"

    cert.subject = subject
    cert.issuer = subject
    cert.public_key = private_key.public_key

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = cert

    cert.add_extension (ef.create_extension 'basicConstraints', 'CA:TRUE', true)
    cert.add_extension (ef.create_extension 'keyUsage', 'keyCertSign, cRLSign', true)
    cert.add_extension (ef.create_extension 'subjectKeyIdentifier', 'hash', false)
    cert.add_extension (ef.create_extension 'authorityKeyIdentifier', 'keyid:always', false)

    cert.sign private_key, OpenSSL::Digest::SHA256.new

    Crypto::Certificate.new private_key, cert
  end

  def generate_daemon_cert ca_cert, ca_private_key
    cert = cert!
    private_key = key!
    uuid = uuid!

    subject = OpenSSL::X509::Name.parse "/UID=#{uuid}#{DAEMON_CERT_NAME}"

    cert.subject = subject
    cert.issuer = ca_cert.subject
    cert.public_key = private_key.public_key

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = ca_cert
    cert.add_extension (ef.create_extension 'keyUsage', 'keyEncipherment, dataEncipherment, digitalSignature', true)
    cert.add_extension (ef.create_extension 'subjectKeyIdentifier', 'hash', false)

    cert.sign ca_private_key, OpenSSL::Digest::SHA256.new

    Crypto::Certificate.new private_key, cert
  end

  def compute_ecdh_key req_ec, public_key
    group = OpenSSL::PKey::EC::Group.new 'prime256v1'
    point = OpenSSL::PKey::EC::Point.new group, OpenSSL::BN.new(public_key, 2)
    req_ec.dh_compute_key point
  end

  def compute_dh_key req_dh, der
    res_dh = OpenSSL::PKey::DH.new der
    res_dh.generate_key!
    req_dh.compute_key res_dh.public_key
  end

  def aes_encrypt key, iv, data
    cipher = OpenSSL::Cipher.new('AES-256-CBC').encrypt
    cipher.key = key
    cipher.iv = iv
    cipher.update(data) + cipher.final
  end

  def aes_decrypt key, iv, data
    cipher = OpenSSL::Cipher.new('AES-256-CBC').decrypt
    cipher.key = key
    cipher.iv = iv
    cipher.update(data) + cipher.final
  end

  def uuid!
    SecureRandom.uuid
  end

  def cipher!
    OpenSSL::Cipher.new CIPHER
  end

  def key!
    OpenSSL::PKey::RSA.new RSA_KEY_SIZE
  end

  def serial_number!
    ret = (SecureRandom.hex 2).to_i 16
    ret > 2 ? ret : serial_number!
  end

  def cert!
    ret = OpenSSL::X509::Certificate.new
    ret.version = 2

    ret.serial = serial_number!

    ret.not_before = Time.now
    ret.not_after = Time.now + 10.years

    ret
  end

  self.extend(self)
end

module Crypto
  class Certificate
    attr_reader :cert

    def initialize key, cert
      @cert = cert
      @key = key
    end

    def public_key
      return nil if !@key
      @key.private? ? @key.public_key : @key
    end

    def private_key
      return nil if !@key
      @key.private? ? @key : nil
    end

    def uuid
      @cert.uuid
    end

    def hash_id
      @cert.hash_id
    end

    def generate_cert
      Crypto.generate_daemon_cert @cert, private_key
    end

    def export_public_key phrase
      public_key.export Crypto.cipher!, phrase
    end

    def export_private_key phrase
      private_key.export Crypto.cipher!, phrase
    end

    def export_cert
      @cert.to_pem
    end

    def write_keypair
      Keypair.create(
        certificate: export_cert,
        public_key: public_key ? public_key.to_pem : nil,
        private_key: private_key ? private_key.to_pem : nil,
        uuid: uuid,
        hash_id: hash_id
      )
    end
  end
end
