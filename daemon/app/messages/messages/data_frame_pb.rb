# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: messages/data_frame.proto

require 'google/protobuf'

require 'models/data_session_pb'
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "proto.DataFrame" do
    optional :uuid, :string, 1
    optional :session, :message, 2, "proto.DataSession"
    optional :raw_data, :bytes, 3
  end
end

module Proto
  DataFrame = Google::Protobuf::DescriptorPool.generated_pool.lookup("proto.DataFrame").msgclass
end
