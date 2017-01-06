# ActiveRecord model which represents a location into which items can be built.
#
# 
# === Fields:
# code:: mandatory, unique 3-15 character code that is used to identify a space in URLs 
# name:: mandatory, string used for the display name of a space
# description:: text field for describing the role of a space
# enabled:: mandatory boolean field whether the space is usable. if no, no submission/workflow can take place
#
class Space < ActiveRecord::Base
  extend ActiveSupport::Memoizable
  
  DEFAULT_INCLUDES = {:item_types => :items}
  
  has_many :roles, :as => :context

  has_many :item_types, :through => :formats
  has_many :formats, :dependent => :destroy

  has_many :items
  has_many :permissions, :as => :permissible, :dependent => :destroy

  belongs_to :workflow
  
  
  validates_presence_of :workflow
  validates_presence_of :name
  validates_presence_of :code
  validates_presence_of :enabled
  
  validates_length_of :code, :within => 2..20
  validates_format_of :code, :with => /^[A-Za-z][A-Za-z0-9_-]+$/, :message => "Code must start with a letter and only include letters, digits, _ and -"
  validates_uniqueness_of :code
  
  def self.find_by_ids_with_permissions(user, actions, tag = Space)
    spaces_permissions = Permission.find_objects_by_context(tag, :user => user, :actions => "View_Space", :permissibles => Workflow)
    
    spaces = {}
    spaces_permissions.each do |space_bundle|
      space, permissions = space_bundle
      items = []
      if permissions.includes_action?("View_All")
        items = Item.find_all_by_space_id(space.id, :order => "items.updated_at desc")
      else
        items = Item.find_all_by_id(Permission.find_tags_by_context(user,space.items,"View").collect(&:id), :order => "items.updated_at desc")
      end
      spaces[space] = {:permissions => permissions, :items => items} 

    end
    
    spaces
  end
  
  
  def to_s
    name
  end
  
  def self.list_permissions_for(user, options={})
    Permission.check(:user => user, :contexts => Space, :actions => options[:actions], :permissible_types => "Workflow", :result => :hash)
  end

  def self.find_spaces_and_permissions(user, options={})
    Permission.check(options.merge({:user => user, :contexts => Space, :permissible_types => "Workflow", :result => :hash, :hash_type => :object}))
  end

  
  def self.create_with_workflow_and_owners(options={})
    owners = Array(options.delete(:owners))
    raise "No owners specified for space creation." unless owners 

    workflow = options[:workflow]
    raise "No workflow found for space creation" unless workflow

    workflow_owner_role_name = options.delete(:workflow_owner_role) || "Administrator"
    workflow_owner_role = Role.find_by_context_type_and_context_id_and_name("Workflow", workflow.id, workflow_owner_role_name)
    
    raise "Role #{workflow_owner_role_name} not found for given workflow" unless workflow_owner_role

    space = nil

    ActiveRecord::Base.transaction do
      space = Space.create!(options)

      role = Role.create(:context => space, :name => "Owner")
      owners.each { |owner| role.assignments.create(:subject => owner)}
      role.children << workflow_owner_role
      role.save!
    end  
    
      
    return space
  end
end
