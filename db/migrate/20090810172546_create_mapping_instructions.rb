class CreateMappingInstructions < ActiveRecord::Migration
  def self.up
    create_table :mapping_instructions, :force => true do |t|
      t.integer :mapping_id, :null => false
      t.integer :parent_id
      t.integer :position, :null => false
      t.string :category, :null => false
      t.text :value
      t.timestamps
    end
    
    add_index :mapping_instructions, [:mapping_id, :parent_id, :position], :name => "by_mapping_parent_and_position"
  end

  def self.down
    drop_table :mapping_instructions
  end
end
