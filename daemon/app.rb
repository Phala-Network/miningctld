require 'rubygems'
require 'bundler'

Bundler.require

require_relative 'app/constants'
Dir["#{APP_PATH}/initializers/**/*.rb"].sort.each { |f| require f }
