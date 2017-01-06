class Attachment < ActiveRecord::Base
  belongs_to :value
  belongs_to :asset
  
  validates_presence_of :value
  validates_presence_of :asset
end
