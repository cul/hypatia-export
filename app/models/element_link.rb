class ElementLink < ActiveRecord::Base
  validates_numericality_of :position, :only_integer => true, :greater_than_or_equal_to => 0
   
  belongs_to :parent, :class_name => "Element", :foreign_key => :parent_id
  belongs_to :child, :class_name => "Element", :foreign_key => :child_id
  
  before_validation(:assign_first_free_position, on: :create) 

  validates_uniqueness_of :child_id, :scope => :parent_id
  validates_uniqueness_of :position, :scope => :parent_id

  validate :no_self_link
  validate :parent_must_be_template


  def update_position_force(position_to_update)
    if position != position_to_update
      links_to_update = []
      position_check = position_to_update
    
      while (conflict = ElementLink.find_by_parent_id_and_position(parent, position_check))
        links_to_update << conflict
        position_check +=1
      end
    
      links_to_update.reverse.each do |link|
        link.position += 1
        link.save!
      end
  
      self.position = position_to_update
      self.save!
    end
    
    return self
    
  end


  private
  def no_self_link
    errors.add_to_base("Parent and Child cannot be the same") unless parent != child
  end
  
  def parent_must_be_template
    errors.add_to_base("Parent must be a template") unless parent.category == "Template"
  end
  
  def assign_first_free_position
    unless self.position
      self.position = first_free_position
    end
    
    true
  end
  
  def first_free_position
    parent.children_links.maximum(:position).to_i + 1
  end
  
end
