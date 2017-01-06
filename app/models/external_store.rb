class ExternalStore < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_presence_of :store_type
  
  def connector
    if store_type == "fedora"
      FEDORA_CONNECTORS[config]
    else
      raise "External Store type not implemented yet"
    end
  end
  
end
