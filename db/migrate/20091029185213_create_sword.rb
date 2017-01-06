class CreateSword < ActiveRecord::Migration
  def self.up
    create_table :swords, :force => true do |t|
      t.string :depositor, :limit => 128
      t.string :sword_pid,  :limit => 32
      t.string :item_id,  :limit => 32
      t.string :ac_pid,  :limit => 32
      t.datetime :received
      t.datetime :uploaded
      t.datetime :item_created
    end
    add_index "swords", ["sword_pid"], :name => "sword_pid", :unique => true
    create_table :sword_deposits, :force => true do |t|
      t.string :file_name, :limit => 120, :null => false
      t.string :content_type, :limit => 80,  :null => false
      t.string :packaging, :limit => 120, :null => false
      t.string :user, :limit => 60,  :null => false
      t.string :on_behalf_of, :limit => 60
      t.string :collection, :limit => 120, :null => false
      t.string :md5_digest, :limit => 100, :null => false
      t.timestamp :received, :null => false
      t.timestamp :embargo_release_date
      t.integer :item_id, :limit => 8
      t.timestamp :item_created
      t.string :pid_id, :limit => 20
      t.timestamp :pid_created
    end
    add_index :sword_deposits, ["md5_digest"], :name => "file_name_index", :unique => true
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end