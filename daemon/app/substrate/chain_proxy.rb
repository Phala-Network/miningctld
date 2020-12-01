CPROXY_URL = ENV['CPROXY_URL'] || 'http://cproxy:7070'

module Substrate::ChainProxy
  def self.bind_stash(controller_ss58:, stash_uri:)
    self.send(
      method: :post,
      url: '/bindStash',
      body: ({
        controllerSs58: controller_ss58,
        stashUri: stash_uri
      }).to_json
    )
  end

  def self.top_up(controller_ss58:, stash_uri:, amount:)
    self.send(
      method: :post,
      url: '/topUp',
      body: ({
        controllerSs58: controller_ss58,
        stashUri: stash_uri,
        amount: amount
      }).to_json
    )
  end

  def self.set_commission(controller_uri:, target:, commission:)
    self.send(
      method: :post,
      url: '/setCommission',
      body: ({
        target: target,
        commission: commission,
        controllerUri: controller_uri
      }).to_json
    )
  end

  def self.set_intention(stash_uri:)
    self.send(
      method: :post,
      url: '/startIntention',
      body: ({
        stashUri: stash_uri
      }).to_json
    )
  end

  def self.unset_intention(stash_uri:)
    self.send(
      method: :post,
      url: '/stopIntention',
      body: ({
        stashUri: stash_uri
      }).to_json
    )
  end

  def self.send(method:, url:, header: {}, body: nil)
    task = Async do |t|
      conn = Faraday.new(
        url: "#{CPROXY_URL}#{url}"
      )
      response = conn.run_request(method, url, body, ({
        "Content-Type" => "application/json",
        **header
      }))
      {
        status: response.status,
        content: response.body,
        response: response
      }
    end

    begin
      task.wait

      if task.result[:status] / 200 === 1 && task.result[:status] % 200 < 100
        JSON.parse task.result[:content]
      else
        raise ::StandardError.new task.result
      end
    rescue => exception
      $logger.debug "REQUEST #{method} #{url}: failed."
      $logger.error exception
      raise exception
    end
  end
end
