class CreateRegisteredDaemons < ActiveRecord::Migration[6.0]
  def change
    create_table :registered_daemons do |t|
      t.string :hash_id, unique: true
      t.string :uuid, unique: true
      t.integer :role, default: 0
      t.integer :management_status, default: 0
      t.text :description
 
      t.timestamps
    end

    add_index :registered_daemons, [:hash_id, :uuid]
    add_index :registered_daemons, :hash_id
    add_index :registered_daemons, :uuid
  end
end
