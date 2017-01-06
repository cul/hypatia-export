class CreateWorkflowTransitions < ActiveRecord::Migration
  def self.up
    create_table :workflow_transitions, :force => true do |t|
      t.integer :start_state_id, :null => false
      t.integer :end_state_id, :null => false
      t.string :name, :null => false, :limit => 40
      t.string :description
      t.timestamps
    end
    
    add_index :workflow_transitions, [:start_state_id, :end_state_id]
  end

  def self.down
    drop_table :workflow_transitions
  end
end
