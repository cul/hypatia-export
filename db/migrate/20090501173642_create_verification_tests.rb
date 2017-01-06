class CreateVerificationTests < ActiveRecord::Migration
  def self.up
    create_table :verification_tests do |t|
      t.integer :set_id, :null => false
      t.integer :element_id
      t.string :category, :null => false
      t.string :query
      t.string :value
      t.string :message
      t.timestamps
    end
    
    add_index :verification_tests, :set_id
  end

  def self.down
    drop_table :verification_tests
  end
end
