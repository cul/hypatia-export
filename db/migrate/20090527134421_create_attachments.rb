class CreateAttachments < ActiveRecord::Migration
  def self.up
    create_table :attachments, :force => true do |t|
      t.integer :value_id, :null => false
      t.integer :asset_id, :null => false
    end
    
    add_index :attachments, :value_id
    add_index :attachments, :asset_id
  end

  def self.down
    drop_table :attachments
  end
end
