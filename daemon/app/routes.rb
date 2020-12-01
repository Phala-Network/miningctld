require_relative 'tunnel'

Cuba.define do
  on root do
    on get do
      res.write '🐸'
    end
  end

  on "provision" do
    on post do
      begin
        encrypted_cert = ProvisioningCode.provision req.body.read
        res.write encrypted_cert
      rescue => err
        $logger.debug err
        res.status = 403
        halt res.finish
      end
    end
  end

  on 'tunnel' do
    run tunnel_handler
  end

  on 'phost_callback/:uuid' do |uuid|
    on post do
      begin
        Ohm.redis.call("PUBLISH", uuid, req.body.read)
        res.status = 418
        res.write 'I am a teapot!'
      rescue => e
        $logger.error e
        res.status = 400
        halt res.finish
      end
    end
  end
end
