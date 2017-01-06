class CreateItemTypes < ActiveRecord::Migration
  def self.up
    create_table :item_types, :force => true do |t|
      t.string :name, :limit => 60, :null => false
      t.integer :element_id, :null => false
      t.string :title_query
      t.text   :description
      t.timestamps
    end
    
    add_index :item_types, :name, :unique => true
    add_index :item_types, :element_id
    
  end

  def self.down
    drop_table :item_types
  end
end
