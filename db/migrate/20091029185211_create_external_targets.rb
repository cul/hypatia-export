class CreateExternalTargets < ActiveRecord::Migration
  def self.up
    create_table :external_targets, :force => true do |t|
      t.integer :external_store_id, :null => false
      t.string :target_type
      t.string :name, :null => false
      t.string :value
      t.timestamps
    end
    add_index :external_targets, [:external_store_id, :target_type], :name => "index_external_targets_on_external_store_id_and_target_type"
  end

  def self.down
    drop_table :external_targets
  end
end
