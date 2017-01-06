class Value < ActiveRecord::Base
  validates_presence_of :item
  validates_presence_of :element
  
  belongs_to :item
  belongs_to :element
  
  acts_as_tree :scope => :item_id
  
  has_many :attachments, :dependent => :destroy
  has_many :assets, :through => :attachments
   
   
  def id_munge(pre = "elements", brackets = true)
    if brackets
      "#{pre.to_s}[#{self.element.id}][#{self.id}]"
    else
      "#{pre.to_s}_#{self.element.id}_#{self.id}"
    end
      
  end
  
  def to_s
    data.to_s
  end
  
  def element_code
    element.code.to_s
  end
  
end
