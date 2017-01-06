class CreateMemberships < ActiveRecord::Migration
  def self.up
    create_table :memberships, :force => true do |t|
      t.integer :user_id, :null => false
      t.integer :group_id, :null => false
    end
  end

  def self.down
    drop_table :memberships
  end
end
