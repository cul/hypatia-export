class CreateWorkflowStatuses < ActiveRecord::Migration
  def self.up
    create_table :workflow_statuses, :force => true do |t|
      t.integer :entity_id, :null => false
      t.string :entity_type, :null => false
      t.integer :workflow_id, :null => false
      t.integer :state_id, :null => false
      t.timestamps
    end
    
    add_index :workflow_statuses, :state_id
    add_index :workflow_statuses, [:entity_id, :entity_type, :workflow_id], :unique => true, :name => "by_entity_and_workflow_id"
  end

  def self.down
    drop_table :workflow_statuses
  end
end
