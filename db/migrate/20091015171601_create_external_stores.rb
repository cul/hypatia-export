class CreateExternalStores < ActiveRecord::Migration
  def self.up
    create_table :external_stores, :force => true do |t|
      t.string :name, :null => false
      t.string :store_type, :null => false
      t.text :config
      t.timestamps
    end
  end

  def self.down
    drop_table :external_stores
  end
end
