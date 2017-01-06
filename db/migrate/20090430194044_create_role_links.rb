class CreateRoleLinks < ActiveRecord::Migration
  def self.up
    create_table :role_links, :force => true do |t|
      t.integer :child_id, :null => false
      t.integer :parent_id, :null => false
    end

    add_index :role_links, :parent_id
    add_index :role_links, :child_id
  end

  def self.down
    drop_table :role_links
  end
end
