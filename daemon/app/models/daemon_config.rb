require 'securerandom'

class DaemonConfig < Ohm::Model
  include OhmModelBase

  attribute :controlled, Type::Boolean
  attribute :endpoint
  reference :keypair, :Keypair

  attribute :role, Type::Symbol

  reference :controller_config, :ControllerConfig
  reference :worker_config, :WorkerConfig
  reference :bridge_config, :BridgeConfig

  def apply_provision_info(info)
    self.update :role => info.daemon_info.role.to_s.downcase.to_sym
  end

  def self.active_config
    self.all.sort(by: :created_at, order: 'DESC').first
  end
end
