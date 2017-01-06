class Role < ActiveRecord::Base

  belongs_to :context, :polymorphic => true
  
  has_many :permissions, :dependent => :destroy
  has_many :assignments, :dependent => :destroy
  
  has_many :groups, :through => :assignments, :source => :subject, :source_type => 'Group'
  has_many :users, :through => :assignments, :source => :subject, :source_type => 'User'
  
  has_many :children, :through => :children_links
  has_many :children_links, :class_name => "RoleLink", :foreign_key => :parent_id, :dependent => :destroy
  
  has_many :parents, :through => :parent_links
  has_many :parent_links, :class_name => "RoleLink", :foreign_key => :child_id, :dependent => :destroy

  named_scope :by_context, lambda { |context| {:conditions => {:context_type => (context.nil? ? nil : context.class.to_s), :context_id => (context.nil? || context.kind_of?(Class) ? nil : context.id)}}}
  
  
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:context_id, :context_type]
  validates_length_of :name, :maximum => 20
  validates_format_of :name, :with => /^[A-Za-z][A-Za-z0-9 _]+$/, :message => "Name must start with a letter and only include letters, digits, spaces, and underscores"
  
  
  
  def to_s
    "#{name}" + (context_type ? " of #{context_type}/#{context_id}" : "")
  end
  
  def context_tag
    ObjectTag[context_type, context_id]
  end
  
  def inspect
    "#<Role id:#{id}, #{name}#{context_type ? " of #{context_type}/#{context_id}" : ""}>"
  end
  def self.find_by_name_and_context(name, context = nil)
    context_type, context_id = context ? [context.class.to_s, context.id] : [nil,nil]
    Role.find_by_name_and_context_type_and_context_id(name, context_type, context_id)
  end

  alias_method :context_assign_original, :"context="
  
  def context=(value)
    if value.kind_of?(Class)
      self.context_type = value.to_s
      self.context_id = "all"
    else
      context_assign_original(value)
    end
  end

  
  alias_method :context_original, :context
  
  def context
    if context_type.nil?
      nil
    elsif context_id == "all"
      context_type.constantize
    else
      context_original
    end
  end
end
