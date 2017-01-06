class CreateLogs < ActiveRecord::Migration
  def self.up
    create_table :logs do |t|
      t.string :level, :limit => 20
      t.string :classification, :null => false
      t.integer :loggable_id, :null => false
      t.string :loggable_type, :null => false
      t.integer :user_id
      t.text :value
      t.timestamps
    end
    
  end

  def self.down
    drop_table :logs
  end
end
