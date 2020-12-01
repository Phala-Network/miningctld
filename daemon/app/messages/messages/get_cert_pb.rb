# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: messages/get_cert.proto

require 'google/protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "proto.GetCertRequest" do
    optional :code, :string, 1
    optional :temp_public_key, :bytes, 2
    optional :nonce, :bytes, 3
  end
  add_message "proto.GetCertResponse" do
    optional :encrypted_cert, :bytes, 1
    optional :temp_public_key, :bytes, 2
    optional :encrypted_key, :bytes, 3
  end
end

module Proto
  GetCertRequest = Google::Protobuf::DescriptorPool.generated_pool.lookup("proto.GetCertRequest").msgclass
  GetCertResponse = Google::Protobuf::DescriptorPool.generated_pool.lookup("proto.GetCertResponse").msgclass
end
