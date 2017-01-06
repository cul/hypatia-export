class Permission < ActiveRecord::Base

  belongs_to :role
  validates_presence_of :role


  belongs_to :permissible, :polymorphic => true
  validates_presence_of :permissible
  
  named_scope :by_permissible, lambda { |permissible| {:conditions => {:permissible_type => (permissible.nil? ? nil : permissible.class.to_s), :permissible_id => (permissible.nil? || permissible.kind_of?(Class) ? nil : permissible.id)}}}
  
  
  
  def to_s
    "#{role.to_s} can #{action_list} on #{permissible.class.to_s}:#{permissible.to_s}"
  end
  

  def inspect
    "#<Permission id: #{id}, permissible: #{permissible_type}/#{permissible_id}, role_id: #{role_id}, action_list: #{action_list}>"
  end
  
  def self.find_objects_by_context(context, options = {})
    options = {:contexts => context, :return => :hash, :key => :object}.merge(options)
    self.check(options)
  end

  def self.find_tags_by_context(user, contexts, *actions)
    tags = []
    Permission.check(:user => user, :contexts => contexts).each do |pa|
      tags << pa[0] if pa[1].includes_action?(*actions)
    end
    
    tags
  end

  
  def self.check_action(user, contexts, *actions)
    Permission.check(:user => user, :contexts => contexts, :key => :object, :actions => actions)
  end
 
  def self.check_action?(user, contexts, *actions)
    !check_action(user,contexts,*actions).empty?
  end
  
  # options: 
  # user (only accepts one)
  # context (limits roles used to a specific context and nested roles)
  # permissibles: limits the various type of permissibles it will return
  # return: hash, array
  # key
  def self.check(options = {})
    
    options = {:contexts => :all, :return => :hash, :key => :context}.merge(options)
    
    conditions = []
    parameters = []
    includes = [:role]
    role_map = nil
    matching_roles =  []
    matching_role_hash = {}
    
    if options[:user]
      role_map = options[:user].role_map

      matching_roles = role_map.find_roles(:contexts => options[:contexts], :nested => false) 
      matching_roles.each { |mr| matching_role_hash[mr] = [mr] | role_map.all_children_of(mr) }
      
      conditions << "roles.id IN(?)"
      parameters << matching_role_hash.values.flatten.uniq.collect(&:id)
    end

    if options[:permissibles]
      perm_conditions, perm_parameters = sql_to_find_permissions(*options[:permissibles])
      conditions << perm_conditions
      parameters += perm_parameters
    end
    

    permissions = self.find(:all, :include => :role,:conditions => [conditions.join(" AND "), *parameters])
    
    case options[:return]
    when :array
      case options[:value]
      when :permissions
        return permissions
      when :actions
        return permissions.collect(&:actions).flatten.uniq  
      end
      
    when :hash
      if options[:key] == :permissible
        rh = PermissibleHash.new
        permissions.each do |p| 
          rh[p.permissible_tag] ||= []
          rh[p.permissible_tag] << p
        end
        
        return rh
      else
        rh = case options[:key]
        when :role
          RoleHash.new
        when :context, :object
          ContextHash.new
        end


      
        matching_roles.each do |role|
          relevant_permissions = permissions.select { |p| matching_role_hash[role].include?(p.role) }

          case options[:key]
          when :role
            rh[role] |= relevant_permissions
          when :context, :object
            rh[role.context_tag] |= relevant_permissions
          end
        end

        if options[:key] == :object
        
          ids = rh.find_ids_by_context_and_actions(options[:contexts], *options[:actions])
          ar_class = ObjectTag[options[:contexts]].global_tag.type.constantize
          find_params = {:include => nil, :conditions => nil}
          find_params.merge!(options[:find_params]) if options[:find_params]
          find_params[:include] = find_params[:include] || (ar_class.const_defined?("DEFAULT_INCLUDES") ? ar_class::DEFAULT_INCLUDES : {})
        
          found_objects = if ids == :all
            ar_class.find(:all, find_params)
          else
            ar_class.find_all_by_id(ids,find_params)
          end
        
          ph = PermissionHash.new
        
          found_objects.each do |found_object|
            ph[found_object] = rh.find_by_context(ObjectTag[found_object])
          end
        
          return ph
      
        else
          return rh
        end
      end
    end
  end


  def has_action?(action)
    actions.include?(action)
  end

  def actions
    action_list.split(",")
  end

  def permissible_tag
    ObjectTag[permissible_type, permissible_id]
  end
  
  protected
  
  
  def self.sql_to_find_permissions(*permissibles)
    conditions, parameters = BuildSql.polymorphic_conditions("permissions.permissible_type", "permissions.permissible_id", *permissibles)
  end
  
end
