# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: models/utils/message_target.proto

require 'google/protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_enum "proto.utils.MessageTarget" do
    value :UNKNOWN, 0
    value :INTERNAL, 1
    value :UI, 2
    value :WORKER, 3
    value :CONTROLLER, 4
    value :BRIDGE, 5
  end
end

module Proto
  module Utils
    MessageTarget = Google::Protobuf::DescriptorPool.generated_pool.lookup("proto.utils.MessageTarget").enummodule
  end
end
