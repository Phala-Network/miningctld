# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: messages/request_provisioning.proto

require 'google/protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "proto.RequestProvisioning" do
    optional :cert, :bytes, 1
    optional :temp_public_key, :bytes, 2
    optional :nonce, :bytes, 3
  end
end

module Proto
  RequestProvisioning = Google::Protobuf::DescriptorPool.generated_pool.lookup("proto.RequestProvisioning").msgclass
end
