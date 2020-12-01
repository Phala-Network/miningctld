$LOAD_PATH.unshift("#{APP_PATH}/messages")
Dir["#{APP_PATH}/messages/**/*.rb"].each { |f| require f }

class << Proto
  def plain_encode **args
    encode_message(
      encrypted: false,
      message: (create_tunnel_message **args)
    )
  end

  def aes_encode key:, iv: ,**args
    encode_message(
      encrypted: true,
      encrypted_message: (Crypto.aes_encrypt key, iv, (encode_tunnel_message **args))
    )
  end

  def aes_decode buffer, key: nil, iv: nil
    message = decode_message buffer
    if message.encrypted
      decode_tunnel_message (Crypto.aes_decrypt key, iv, message.encrypted_message)
    else
      message.message
    end
  end

  def rsa_encode public_key:, **args
    encode_message(
      encrypted: true,
      encrypted_message: (public_key.public_encrypt (encode_tunnel_message **args))
    )
  end

  def plain_or_rsa_decode buffer, private_key: nil
    message = decode_message buffer
    if message.encrypted
      decode_tunnel_message (private_key.private_decrypt message.encrypted_message)
    else
      message.message
    end
  end

  def encode_message **args
    Proto::Message.encode (Proto::Message.new **args)
  end

  def encode_tunnel_message **args
    Proto::TunnelMessage.encode (create_tunnel_message **args)
  end

  def create_tunnel_message **args
    Proto::TunnelMessage.new **args
  end

  def decode_message buffer
    Proto::Message.decode buffer
  end

  def decode_tunnel_message buffer
    Proto::TunnelMessage.decode buffer
  end
end

module Proto
  class TunnelMessage
    def handler
      ('handle_' + self.payload.to_s).to_sym
    end

    def payload!
      send self.payload
    end
  end
end