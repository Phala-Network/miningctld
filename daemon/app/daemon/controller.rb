class Daemon::Controller
  attr_reader :parent
  attr_reader :chain_conn

  def initialize(parent)
    @parent = parent
    @chain_conn = Substrate::Connection.new
  end
end
