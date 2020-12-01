# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: models/daemon_info.proto

require 'google/protobuf'

require 'models/worker_info_pb'
require 'models/controller_info_pb'
require 'models/bridge_info_pb'
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "proto.DaemonInfo" do
    optional :uuid, :string, 1
    optional :public_key, :string, 2
    optional :role, :enum, 3, "proto.DaemonInfo.Role"
    oneof :role_info do
      optional :worker_info, :message, 4, "proto.WorkerInfo"
      optional :controller_info, :message, 5, "proto.ControllerInfo"
      optional :bridge_info, :message, 6, "proto.BridgeInfo"
    end
  end
  add_enum "proto.DaemonInfo.Role" do
    value :UNSET, 0
    value :WORKER, 1
    value :CONTROLLER, 2
    value :BRIDGE, 3
  end
end

module Proto
  DaemonInfo = Google::Protobuf::DescriptorPool.generated_pool.lookup("proto.DaemonInfo").msgclass
  DaemonInfo::Role = Google::Protobuf::DescriptorPool.generated_pool.lookup("proto.DaemonInfo.Role").enummodule
end