class CreateRoles < ActiveRecord::Migration

  def self.up
    create_table :roles, :force => true do |t|
      t.string  :context_type
      t.string  :context_id
      t.string  :name, :limit => 20, :null => false
      t.text    :description
      t.timestamps
    end
    
  end

  def self.down
    drop_table :roles
  end

end
