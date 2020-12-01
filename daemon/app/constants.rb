APP_PATH = Pathname.new(File.dirname(__FILE__)).join('.')
CONFIG_BASE = Pathname.new(APP_PATH).join('../config')

CERT_TYPE = lambda { |pk| pk ? (OpenSSL::X509::Certificate.new pk) : nil }
KEY_TYPE = lambda { |pk| pk ? (OpenSSL::PKey::RSA.new pk) : nil }

def environment
  ENV['RACK_ENV']
end

def development?
  environment === 'development'
end

def running_config
  DaemonConfig.active_config
end
