class CreateAssignments < ActiveRecord::Migration
  def self.up
    create_table :assignments, :force => true do |t|
      t.integer :subject_id, :null => false
      t.string  :subject_type, :null => false
      t.integer :role_id, :null => false
    end
    
    add_index :assignments, [:subject_type,:subject_id, :role_id], :unique => true, :name => "by_subject_and_role"
    add_index :assignments, :role_id
  end

  def self.down
    drop_table :assignments
  end
end
