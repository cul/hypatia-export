class CreateMappingItemTypes < ActiveRecord::Migration
  def self.up
    create_table :mapping_item_types, :force => true  do |t|
      t.integer :mapping_id, :null => false
      t.integer :item_type_id, :null => false
      t.string :code, :null => false
      t.integer :minimum, :null => false, :default => 1
      t.integer :maximum, :default => 1
      t.timestamps
    end
    add_index :mapping_item_types, [:mapping_id, :item_type_id], :name => 'index_mapping_item_types_on_mapping_id_and_item_type_id'
    #add_index :mapping_item_types, [:mapping_id, :item_type_id], :name => 'mapping_item_type_join'
    add_index :mapping_item_types, [:mapping_id, :code]
  end

  def self.down
    drop_table :mapping_item_types
  end
end
