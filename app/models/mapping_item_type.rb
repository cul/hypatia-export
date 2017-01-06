class MappingItemType < ActiveRecord::Base
  belongs_to :mapping
  belongs_to :item_type
  
  validates_presence_of :mapping
  validates_presence_of :item_type
  
  validates_presence_of :code
  validates_uniqueness_of :code, :scope => :mapping_id
  
  validates_numericality_of :minimum, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :maximum, :only_integer => true, :allow_nil => true, :greater_than => 0
  
  def to_s
    "#{mapping.to_s} - #{item_type.to_s}"
  end
  
end
