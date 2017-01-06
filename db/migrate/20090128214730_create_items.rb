class CreateItems < ActiveRecord::Migration
  def self.up
    create_table :items, :force => true do |t|
      t.integer :item_type_id, :null => false
      t.integer :space_id
      t.string  :title
      t.timestamps
    end
    
    add_index :items, :item_type_id
    add_index :items, :space_id
  end

  def self.down
    drop_table :items
  end
end
