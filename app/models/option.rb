class Option < ActiveRecord::Base
  belongs_to :entity, :polymorphic => true
  validates_presence_of :name
  
  def self.system_wide
    self.find_all_by_name_and_entity_id_and_entity_type(nil,nil)
  end
  
  def self.[](name)
    options = self.find_all_by_name_and_entity_id_and_entity_type(name.to_s, nil, nil)
    
    case options.length
    when 0
      nil
    when 1
      options.first.value.to_s
    else
      options.collect { |o| o.value.to_s }
    end
  end

  def _delete

  end

  def to_s
    value.to_s
  end

end
