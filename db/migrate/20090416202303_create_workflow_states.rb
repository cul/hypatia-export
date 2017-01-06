class CreateWorkflowStates < ActiveRecord::Migration
  def self.up
    create_table :workflow_states, :force => true do |t|
      t.string :name, :null => false, :limit => 30
      t.string :description
      t.integer :workflow_id, :null => false

      t.timestamps
    end
    
    add_index :workflow_states, [:workflow_id, :name], :unique => true
  end

  def self.down
    drop_table :workflow_states
  end
end
