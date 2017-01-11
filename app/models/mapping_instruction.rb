class MappingInstruction < ActiveRecord::Base
  CATEGORY_TYPES = %w{build_temp_dir clean_temp_dir eval_template}

  include Optionable

  validates_presence_of :mapping
  belongs_to :mapping
  
  validates_presence_of :category
  validates_inclusion_of :category, :in => CATEGORY_TYPES
  
  before_validation_on_create :assign_first_free_position
  before_validation_on_create :copy_mapping

  validates_uniqueness_of :position, :scope => [:mapping_id, :parent_id]
  validates_numericality_of :position, :only_integer => true, :greater_than_or_equal_to => 0

  
  acts_as_tree :scope => :mapping_id, :order => "position"
  
  has_options
  accepts_nested_attributes_for :options, :allow_destroy => true, :reject_if => proc { |attrs| attrs.all? {|k,v| v.blank? }}


  
  def copy_mapping
    if parent && mapping.nil?
      self.mapping = parent.mapping
    end
  end
  
  
  def assign_first_free_position
    unless self.position
      self.position = first_free_position
    end
    
    true
  end
  
  def first_free_position
    if parent
      parent.children.maximum(:position).to_i + 1
    else
      mapping.instructions.maximum(:position).to_i  + 1
    end
  end

  
end
