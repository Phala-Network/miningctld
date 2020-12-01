Dir["#{APP_PATH}/models/**/*.rb"].each { |f| require f }
Dir["#{APP_PATH}/utils/**/*.rb"].each { |f| require f }
Dir["#{APP_PATH}/handlers/**/*.rb"].each { |f| require f }

Cuba.use Rack::Session::Cookie, :secret => ENV['API_COOKIE_SECRET']

Cuba.plugin GetSetterPlugin
Cuba.plugin ActiveRecordPlugin
Cuba.plugin AppPlugin
Cuba.plugin DaemonPlugin

require_relative '../routes'
