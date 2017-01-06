class CreateVerificationSets < ActiveRecord::Migration
  def self.up
    create_table :verification_sets do |t|
      t.string :name, :null => false
      t.timestamps
    end
    
  end

  def self.down
    drop_table :verification_sets
  end
end
