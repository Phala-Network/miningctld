# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: models/utils/account.proto

require 'google/protobuf'

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "proto.Account" do
    optional :account_id, :string, 1
    optional :public_key, :string, 2
    optional :secret_phrase, :string, 3
    optional :secret_seed, :string, 4
    optional :ss58_address, :string, 5
  end
end

module Proto
  Account = Google::Protobuf::DescriptorPool.generated_pool.lookup("proto.Account").msgclass
end
