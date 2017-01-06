class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users, :force => true do |t|
      t.string :first_name, :limit => 30, :null => false
      t.string :last_name, :limit => 40, :null => false
      t.string :email, :limit => 50, :null => false
      t.string :federation, :limit => 12
      t.string :uid, :limit => 20
      t.timestamps
    end

    add_index :users, [:federation, :uid], {:unique => true}
    add_index :users, [:last_name, :first_name]
  end

  def self.down
    drop_table :users
  end
end


