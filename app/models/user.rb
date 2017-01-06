class User < ActiveRecord::Base
  
  extend ActiveSupport::Memoizable
  
  has_many :groups, :through => :memberships
  has_many :memberships, :dependent => :destroy

  has_many :roles, :through => :assignments
  has_many :assignments, :as => :subject, :dependent => :destroy

  # Validation
  validates_length_of :first_name, :maximum => 30
  validates_length_of :last_name, :maximum => 40
  validates_length_of :email, :maximum => 50
  validates_length_of :federation, :maximum => 12, :allow_nil => false
  validates_length_of :uid, :maximum => 20, :allow_nil => false
  
  validates_uniqueness_of :uid, :scope => :federation, :allow_nil => true
  
  validates_format_of :email, :with => /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}$/i

  


  def personal_space
    Space.find_by_code(personal_space_code)
  end

  def personal_space_code
    "p_#{federation}_#{uid}"
  end

  # TODO: are these errors being handled?
  def create_personal_space!
    if personal_space
      raise "Personal space already exists"
    else
      workflow = Workflow.find_by_id(Option["default_personal_space_workflow"])
      workflow_create_role = Option["default_personal_space_owner_role"]
      workflow_owner_role = Option["default_personal_space_creator_role"]
      item_types = Option["default_personal_space_item_types"].to_s.split(",")
      
      raise "Default Personal Space Workflow not specified in preferences" unless workflow && workflow_create_role && workflow_owner_role
      
      s = Space.create_with_workflow_and_owners(:code => personal_space_code, :name => "Personal Space for #{name}", :workflow => workflow, :enabled => true, :owners => self, :workflow_owner_role => workflow_owner_role, :workflow_create_role => workflow_create_role)
      
      item_types.collect { |it| ItemType.find_by_id(it)}.compact.each do |it|
        s.formats.create!(:item_type => it)
      end
      
      return s
    end
    

  end
  
  def self.build_from_uni(uni, options ={})
    user = User.new(:federation => "Columbia", :uid => uni)

    details = Systems::CUNIX::LDAP.lookup_users(uni)[uni]

    if details
      middle = details[:cumiddlename].to_s

      user.first_name = "#{details[:givenname].to_s}#{middle ? " #{middle}": ""}"
      user.last_name = details[:sn].to_s
      user.email = details[:mail].to_s
    else
      user.first_name = uni
      user.last_name = ""
      user.email = "#{uni}@columbia.edu"
    end
    
    user.save!
    
    user.assignments.create(:role => Role.find_by_name_and_context("User", nil)) unless options[:disabled] == true
    user.create_personal_space! if options[:build_personal_space] == true
    
    return user    
  end
  
  
  
  
  def name
    [first_name, last_name].join(" ")
  end

  def to_s
    name
  end

  def to_label
    "#{name} - #{federation}:#{uid}"
  end
  
  
  # this could be more efficient (or just make it a binary tree)
  def role_map
    base_conditions = '((assignments.subject_type = "User" AND assignments.subject_id = ?) OR (assignments.subject_type = "Group" AND assignments.subject_id IN (?)))' 
    base_parameters = [self.id, groups.collect(&:id)]
  
    base_roles = Assignment.find(:all, :select => :role_id, :conditions => [base_conditions, *base_parameters]).collect(&:role_id)

    link_hash = Hash.new { |h,k| h[k] = []}
    child_hash = Hash.new { |h,k| h[k] = []}
  
    to_find = base_roles.dup
    all_roles = []
    until to_find.empty?
      all_roles |= to_find
      links = RoleLink.find_all_by_parent_id(to_find)
      to_find.clear
    
      links.each do |link| 
        parent, child = link.parent_id, link.child_id
        link_hash[parent] << child
        to_find << child unless link_hash.has_key?(child)
      end
    end
  
    return RoleMap.new(Role.find_all_by_id(all_roles), link_hash)
  end

  
  def has_role?(options = {})
    self.role_map.has_role?(options)
  end

  memoize :role_map
  memoize :has_role?
  memoize :name
end

