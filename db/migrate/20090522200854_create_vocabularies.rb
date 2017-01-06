class CreateVocabularies < ActiveRecord::Migration
  def self.up
    create_table :vocabularies, :force => true do |t|
      t.string :name, :null => false
      t.text :description
      t.timestamps
    end
  end

  def self.down
    drop_table :vocabularies
  end
end
