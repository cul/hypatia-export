class CreateOptions < ActiveRecord::Migration
  def self.up
    create_table :options do |t|
      t.integer :entity_id
      t.string  :entity_type
      t.string  :name, :null => false
      t.text    :value, :default => ""
    end
    
  end

  def self.down
    drop_table :options
  end
end
