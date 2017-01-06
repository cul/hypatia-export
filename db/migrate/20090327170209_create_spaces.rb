class CreateSpaces < ActiveRecord::Migration
  def self.up
    create_table :spaces, :force => true do |t|
      t.string :code, :null => false, :limit => 35
      t.string :name, :null => false
      t.integer :workflow_id, :null => false
      t.string :workflow_create_role
      t.text :description
      t.boolean :enabled, :default => true, :null => false
      t.timestamps
    end
    
    add_index :spaces, :code, :unique => true
    add_index :spaces, :workflow_id
  end

  def self.down
    drop_table :spaces
  end
end
