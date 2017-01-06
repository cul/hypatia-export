class ExternalTarget < ActiveRecord::Base
  belongs_to :external_store
  
  validates_presence_of :external_store
  validates_presence_of :name
end
