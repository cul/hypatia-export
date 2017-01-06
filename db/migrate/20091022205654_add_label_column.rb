class AddLabelColumn < ActiveRecord::Migration
  def self.up
    add_column :elements, :display_name, :string
  end

  def self.down
    remove_column :elements, :display_name
  end
end