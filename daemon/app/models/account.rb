class Account < Ohm::Model
  include OhmModelBase

  attribute :account_id
  attribute :public_key
  attribute :secret_phrase
  attribute :secret_seed
  attribute :ss58_address

  def print
    puts(JSON.pretty_generate self.to_hash)
  end

  def to_hash
    super.merge(
      account_id: account_id,
      public_key: public_key,
      secret_phrase: secret_phrase,
      secret_seed: secret_seed,
      ss58_address: ss58_address,
      uuid: uuid
    )
  end

  def to_proto
    Proto::Account.new(
      account_id: account_id,
      public_key: public_key,
      secret_phrase: secret_phrase,
      secret_seed: secret_seed,
      ss58_address: ss58_address,
    )
  end

  def to_worker_account
    WorkerAccount.new(
      account_id: account_id,
      public_key: public_key,
      ss58_address: ss58_address,
    )
  end

  def bind_stash
    res = Substrate::ChainProxy.bind_stash(
      stash_uri: secret_seed,
      controller_ss58: ss58_address
    )
    puts JSON.pretty_generate(res)
    res
  end

  def top_up(amount = 10) # unit: 1 PHA
    stash_uri = DaemonConfig.active_config.controller_config.account.secret_seed
    res = Substrate::ChainProxy.top_up(
      stash_uri: stash_uri,
      controller_ss58: ss58_address,
      amount: amount
    )
    puts JSON.pretty_generate(res)
    res
  end

  def set_commission(commission = 100)
    stash = ENV['COMMISSION_TARGET_ACCOUNT'] || DaemonConfig.active_config.controller_config.account.ss58_address
    res = Substrate::ChainProxy.set_commission(
      target: stash,
      commission: commission,
      controller_uri: secret_seed
    )
    puts JSON.pretty_generate(res)
    res
  end

  def self.generate
    key = Substrate::Key.generate
    self.create(
      :account_id => key['accountId'],
      :public_key => key['publicKey'],
      :secret_phrase => key['secretPhrase'],
      :secret_seed => key['secretSeed'],
      :ss58_address => key['ss58Address']
    )
  end
end

class WorkerAccount < Ohm::Model
  include OhmModelBase

  attribute :account_id
  attribute :public_key
  attribute :ss58_address

  def print
    puts(JSON.pretty_generate self.to_hash)
  end

  def to_proto
    Proto::Account.new(
      account_id: account_id,
      public_key: public_key,
      ss58_address: ss58_address
    )
  end

  def to_hash
    super.merge(
      account_id: account_id,
      public_key: public_key,
      ss58_address: ss58_address
    )
  end
end

