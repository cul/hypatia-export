class CreateWorkflowTransitionActions < ActiveRecord::Migration
  def self.up
    create_table :workflow_transition_actions, :force => true do |t|
      t.integer :transition_id, :null => false
      t.string :category, :null => false, :limit => 20
      t.string :title, :null => false
      t.integer :position, :null => false
      t.boolean :run_before, :null => false      
      t.timestamps
    end
    
    add_index :workflow_transition_actions, [:transition_id, :run_before, :position], :unique => true, :name => "by_transition_and_run_position"
  end

  def self.down
    drop_table :workflow_transition_actions
  end
end
