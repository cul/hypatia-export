class AddCategoryTypeToElements < ActiveRecord::Migration
  def self.up
    # add_column :elements, :field_type, :string, :limit => 20
    # 
    # Element.find_all_by_category("Field").each do |e|
    #   option_type = e.find_option_value("type")
    #   e.update_attributes(:field_type => option_type) unless option_type.to_s == ""
    # end
    # 
    # Option.find_all_by_entity_type_and_name("Element", "type").each { |opt| opt.destroy}
    # 
  end

  def self.down
    
    # Element.find_all_by_category("Field").each do |e|
    #   e.options.create(:name => "type", :value => e.field_type)
    # end
    # 
    # remove_column :elements, :field_type
  end
end
