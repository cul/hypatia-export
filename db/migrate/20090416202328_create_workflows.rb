class CreateWorkflows < ActiveRecord::Migration
  def self.up
    create_table :workflows, :force => true do |t|
      t.string :name, :null => false, :limit => 50
      t.string :description
      t.integer :start_state_id
      t.timestamps
    end
  end

  def self.down
    drop_table :workflows
  end
end
