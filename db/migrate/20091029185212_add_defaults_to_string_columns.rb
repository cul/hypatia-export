class AddDefaultsToStringColumns < ActiveRecord::Migration

  def self.up
    change_column_default(:options, :name, '')
    change_column_default(:options, :value, nil) # from ''

  end

  def self.down

    change_column_default(:options, :name, nil)
    change_column_default(:options, :value, '')
  end
end
