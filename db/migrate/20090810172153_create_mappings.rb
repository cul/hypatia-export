class CreateMappings < ActiveRecord::Migration
  def self.up
    create_table :mappings, :force => true do |t|
      t.string :name, :null => false
      t.text :description
      t.string :store_type
      t.timestamps
    end
  end

  def self.down
    drop_table :mappings
  end
end
