class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.integer :permissible_id, :null => false
      t.string  :permissible_type, :null => false
      t.integer :role_id, :null => false
      t.text    :action_list
      t.timestamps
    end
    
    add_index :permissions, [:role_id]
    add_index :permissions, [:permissible_id, :permissible_type], :name => 'index_permissions_on_permissible_id_and_permissible_type'
  end

  def self.down
    drop_table :permissions
  end
end
