class CreateVocabularyMembers < ActiveRecord::Migration
  def self.up
    create_table :vocabulary_members do |t|
      t.integer :vocabulary_id, :null => false
      t.integer :parent_id
      t.string :name, :null => false
      t.string :value
      t.integer :position, :default => 0
    end
  end

  def self.down
    drop_table :vocabulary_members
  end
end
