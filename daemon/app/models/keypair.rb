class Keypair < Ohm::Model
  include OhmModelBase

  attribute :certificate, CERT_TYPE
  attribute :public_key, KEY_TYPE
  attribute :private_key, KEY_TYPE
  attribute :hash_id

  index :hash_id

  def to_crypto_cert
    Crypto::Certificate.new (private_key || public_key), certificate
  end

  def valid?
    cert = to_crypto_cert
    cert.hash_id === hash_id && cert.uuid === uuid
  end
end
