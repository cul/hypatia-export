class Format < ActiveRecord::Base
  belongs_to :item_type
  belongs_to :space
  
  validates_presence_of :item_type
  validates_presence_of :space
end
