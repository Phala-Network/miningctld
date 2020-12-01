class ControllerConfig < Ohm::Model
  include OhmModelBase

  attribute :ca_pass_phrase
  reference :ca_keypair, :Keypair

  reference :account, :Account
end
