# ActiveRecord model which represents a class of items (journal article, image, Oral History Object)
# 
# === Fields:
# name:: mandatory, unique <60 character identifier for na item type. 
# description:: text field for describing the role of an item_type
#
# == Associations:
# items (many):: each item_type links to any number of items which subscribe to it.
# element (belongs):: this represents the element out of which to build the schema for the item_type
# spaces (habtm):: each item_type can be associated with any number of spaces. If an item_type is not associated with a space, it cannot be created
#
# TODO: what should happen when the element is changed
# TODO: what should happen when an item_type is pulled out of a space.
#
class ItemType < ActiveRecord::Base
  
  
  has_many :items
  
  has_many :spaces, :through => :formats
  has_many :formats, :dependent => :destroy
  
  has_many :mappings, :through => :mapping_item_types
  has_many :mapping_item_types, :dependent => :destroy
  
  belongs_to :element
  
  validates_presence_of :name
  validates_length_of :name, :in => 3..60
  validates_uniqueness_of :name
  
  validates_presence_of :element
  
  def to_s
    name
  end
  
  def nested_codes
    element.nested_codes
  end
end
