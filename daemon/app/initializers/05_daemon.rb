require 'async/io/stream'
require 'async/http/endpoint'
require 'async/websocket/client'
require 'async/websocket/adapters/rack'

module Async
  module WebSocket
    class Connection < ::Protocol::WebSocket::Connection
      def read
        if buffer = super
          buffer
        end
      end
      
      def write(buffer)
        super(buffer)
      end
    end
  end
end

class Cuba
  def self.enumerate_message connection
    Enumerator.new do |yielder|
      while (message = connection.read)
        yielder << message
      end
    end
  end
end

class Daemon
end

class Daemon::Controller
end

class Daemon::Bridge
end

class Daemon::Worker
end

class Daemon::Internal
end

Dir["#{APP_PATH}/daemon/**/*.rb"].each { |f| require f }

module DaemonPlugin
  module ClassMethods
    def daemon
      @daemon
    end
  end

  def self.included base
    base.instance_variable_set :@daemon, (Daemon.new base)
  end
end
