class CreateValues < ActiveRecord::Migration
  def self.up
    create_table :values, :force => true do |t|
      t.integer :item_id, :null => false
      t.integer :element_id, :null => false
      t.integer :parent_id
      t.text :data
      t.timestamps
    end
    
    add_index :values, [:item_id, :element_id, :parent_id]
  end

  def self.down
    drop_table :values
  end
end
