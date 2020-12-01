require 'async'
require 'async/redis'

ASYNC_REDIS_ENDPOINT = Async::IO::Endpoint.tcp(ENV['REDIS_HOST'], ENV['REDIS_PORT'].to_i)

Ohm.redis = Redic.new("redis://#{ENV['REDIS_HOST']}:#{ENV['REDIS_PORT']}")

module OhmModelBase
  def self.included base
    base.include Ohm::DataTypes
    base.include Ohm::Timestamps
    base.include Ohm::Callbacks
  
    base.attribute :uuid
    base.index :uuid
    base.unique :uuid

    base.define_method :before_create do
      self._set_uuid
    end

    def _set_uuid
      self.uuid ||= SecureRandom.uuid
    end
  end
end

def async_redis_client
  Async::Redis::Client.new(ASYNC_REDIS_ENDPOINT)
end
