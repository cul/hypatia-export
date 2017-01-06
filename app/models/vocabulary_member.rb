class VocabularyMember < ActiveRecord::Base
  belongs_to :vocabulary
  
  validates_presence_of :vocabulary
  validates_presence_of :name
  validates_numericality_of :position, :allow_nil => true, :only_integer => true
  
  acts_as_tree :scope => :vocabulary_id, :order => "position, name"

  def member_value
    value.to_s == "" ? name : value
  end
  
  
end
