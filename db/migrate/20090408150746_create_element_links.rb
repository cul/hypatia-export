class CreateElementLinks < ActiveRecord::Migration
  def self.up
    create_table :element_links, :force => :true do |t|
      t.integer :child_id, :null => false
      t.integer :parent_id, :null => false
      t.integer :position, :null => false
      t.timestamps
    end
    
    add_index :element_links, :parent_id
    add_index :element_links, [:parent_id, :position], :unique => true
    add_index :element_links, [:parent_id, :child_id], :unique => true
    add_index :element_links, :child_id
  end

  def self.down
    drop_table :element_links
  end
end
