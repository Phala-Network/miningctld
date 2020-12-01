require_relative 'app'
require 'falcon/command/serve'

begin
  Falcon::Command::Serve.call
rescue Interrupt
end
