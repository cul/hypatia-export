class Vocabulary < ActiveRecord::Base
  has_many :members, :class_name => "VocabularyMember", :foreign_key => "vocabulary_id", :order => "parent_id, position, name"
  
  validates_presence_of :name
  validates_uniqueness_of :name
  
  def base_members
    self.members.find_all_by_parent_id(nil)
  end
  
end
