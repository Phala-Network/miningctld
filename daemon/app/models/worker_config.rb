class WorkerConfig < Ohm::Model
  include OhmModelBase

  reference :account, :WorkerAccount
end
