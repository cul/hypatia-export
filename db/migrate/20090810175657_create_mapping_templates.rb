class CreateMappingTemplates < ActiveRecord::Migration
  def self.up
    create_table :mapping_templates, :force => true do |t|
      t.string :name, :null => false
      t.text :value

      t.timestamps
    end
    
    add_index :mapping_templates, :name
  end

  def self.down
    drop_table :mapping_templates
  end
end
