class AddWorkerAccount < ActiveRecord::Migration[6.0]
  def change
    add_column :registered_daemons, :account, :json
  end
end
