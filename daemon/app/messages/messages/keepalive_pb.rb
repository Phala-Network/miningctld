# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: messages/keepalive.proto

require 'google/protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "proto.Keepalive" do
    optional :is_responder, :bool, 1
  end
end

module Proto
  Keepalive = Google::Protobuf::DescriptorPool.generated_pool.lookup("proto.Keepalive").msgclass
end