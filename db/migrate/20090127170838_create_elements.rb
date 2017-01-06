class CreateElements < ActiveRecord::Migration
  def self.up
    create_table :elements, :force => true do |t|
      t.string  :category, :null => false
      t.string  :name, :null => false
      t.string  :code, :limit => 25, :null => false
      t.text    :description
      t.integer :minimum, :default => 1
      t.integer :maximum, :default => 1
      t.timestamps
      t.string  :field_type, :limit => 20
    end
    
    add_index :elements, :code
  end

  def self.down
    drop_table :elements
  end
end
