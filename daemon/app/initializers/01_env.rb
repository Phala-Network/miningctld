require 'securerandom'
require 'logger'
require 'active_record'
require 'async/http/faraday/default'


$logger = Logger.new(STDOUT)
$logger.level = Logger::DEBUG if development?
