class WorkerStates < Ohm::Model
  include OhmModelBase

  attribute :status, Type::Symbol
  attribute :registered_daemon, Type::Integer
  attribute :pending_set_intention, Type::Boolean

  index :status
  index :registered_daemon

  def daemon
    RegisteredDaemon.find(registered_daemon)
  end

  def set_intention
    return nil if pending_set_intention

    begin
      $logger.info "Daemon \##{daemon.uuid}(#{daemon.id}, #{daemon.role}, #{daemon.description}): start_mining_intention"
      update :pending_set_intention => true

      stash_uri = daemon.account.secret_seed
      res = Substrate::ChainProxy.set_intention(
        stash_uri: stash_uri
      )
      puts JSON.pretty_generate(res)
      res
    ensure
      update :pending_set_intention => false
    end
  end
end
