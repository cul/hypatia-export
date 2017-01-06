class CreateExports < ActiveRecord::Migration
  def self.up
    create_table :exports, :force => true do |t|
      t.integer :external_store_id, :null => false
      t.integer :item_id, :null => false
      t.integer :mapping_id
      t.timestamps
    end
    
    add_index :exports, :item_id    
  end

  def self.down
    drop_table :exports
  end
end
