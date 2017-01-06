class SwitchToStateWorkflow < ActiveRecord::Migration
  def self.up
    remove_column :workflows, :start_state_id
    remove_column :workflows, :description
    change_table (:items) do |t|
      t.string :status, :limit => 50
    end
    Item.find(:all).each { |i| i.update_attributes(:status => i.status.gsub(/ /,"").underscore) }
    
    
    add_index :items, [:space_id, :status]

    drop_table :workflow_transitions
    drop_table :workflow_transition_actions
    drop_table :workflow_statuses
    drop_table :workflow_states
    drop_table :taggings
    drop_table :tags
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
