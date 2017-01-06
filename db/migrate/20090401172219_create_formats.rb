class CreateFormats < ActiveRecord::Migration
  def self.up
    create_table :formats, :force => true do |t|
      t.integer  :item_type_id, :null => false
      t.integer  :space_id, :null => false
    end
  end

  def self.down
    drop_table :formats
  end
end
