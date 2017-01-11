# ActiveRecord model which represents one item (a collection of metadata and objects)
# 
# === Fields:
#
# == Associations:
# item_type (belongs):: describes the type of item is, specifices the schema to follow
# space (belongs): mandatory, represents the current space it belongs to
# values (many):: represents all of the metadata and files blobs.
#
class Item < ActiveRecord::Base  
  has_many :values, :dependent => :destroy

  validates_presence_of :item_type
  belongs_to :item_type
  belongs_to :space
  
  has_many :logs, -> { order("created_at DESC")}, :as => :loggable
  has_many :exports
  has_many :sword_deposits

  before_create :set_starting_state

  def make_copy(values_to_copy)
    new_item = Item.create!(:item_type => item_type, :space => space)
    values_to_copy = values_to_copy.collect(&:to_i)
    added_values = copy_element_values(new_item, nil, nil, item_type.element,values_to_copy)

    new_item.update_attributes(:title => new_item.title_query)
    return new_item, added_values
  end

  def copy_element_values(new_item, current_parent, new_parent, current_element, values_to_copy)
    values = Value.find_all_by_item_id_and_parent_id_and_element_id(self, current_parent, current_element)
    added_values = []
    
    values.each do |value|
      copied_values = []

      new_value = Value.create(:parent => new_parent, :element => current_element, :item => new_item, :data => value.data)
      
      if current_element.category == "Field"
        copied_values << new_value if value.id.in?(values_to_copy)
      else
        current_element.children.each do |child|
          new_values = copy_element_values(new_item, value, new_value, child, values_to_copy)
          
          if value.id.in?(values_to_copy) || !new_values.empty?
            copied_values << new_value
            added_values |= new_values
          end
        end
      end
      
      
      if copied_values.empty?
        new_value.destroy 
      else
        added_values << new_value
      end
    end
    
    return added_values
  end

  def set_starting_state
    machine = self.workflow_machine
    machine.update_base_if_exists if machine
  end  

  cattr_reader :per_page
  @@per_page = 10
    
  def owners
    return @owners if defined? @owners
    role = Role.find_by_context_type_and_context_id_and_name("Item", self.id, "Owner")
    @owners = role ? role.assignments.collect(&:users).flatten.uniq : []
  end


  def can_edit?(user)
    return @editable if defined? @editable
    @editable = check_permissions(user).check_action(workflow, "Edit_#{status}", "Edit_All")
  end

  def can_export?(user)
    check_permissions(user).check_action(workflow, "Export") && (workflow_machine && workflow_machine.can_export?)  
  end

  
  def workflow
    space && space.workflow
  end

  def workflow_machine
    space && space.workflow && space.workflow.machine_from_base(self, :status)
  end

  
  def find_or_create_oriented_values(element, parent, minimum = 1)
    result = find_oriented_values(element,parent) 
    (minimum - result.length).times { result << create_oriented_value(element,parent)}
    
    result
  end
  
  def find_oriented_values(element, parent)
    result = self.values.find_all_by_element_id_and_parent_id(element,parent)
  end
  
  def create_oriented_value(element, parent)
    self.values.create(:element => element, :parent => parent, :data => oriented_value_default(element,parent))
  end
  
  def oriented_value_default(element, parent)
    element.find_option_value(:default)
  end
  
  
  def check_permissions(user = nil)
    return @permissible if defined? @permissible
    @permissible = Permission.check(:user => user, :contexts => [self, ObjectTag["Space", self.space_id]], :key => :permissible)
  end
  
  def audits?
    
  end
  
  def audit
    
  end
   
  def root_element
    self.item_type && self.item_type.element
  end

  def to_xml(options = {})
    options[:indent] ||= 2
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]

    xml.item do
      xml.metadata do
        xml.space(space.to_s, :id => space.id)
        xml.id(id.to_s, :type => "integer")
        xml.created_at(created_at.to_s, :type => "datetime")
        xml.updated_at(updated_at.to_s, :type => "datetime")
      end
      if item_type.element
        xml.data do
          item_type.element.to_xml(:builder => xml, :skip_instruct => true, :style => :data, :item => self)         
        end
      end
    end   
  end
  
  def values_hash
    values.collect { |v| v.data }.compact.join(";~;")
  end
  
  
  def title_query
    begin
      self.title = query_values(item_type.title_query, :return => :single).to_s if item_type.title_query
    rescue
      
    end
  end
  
  def to_s
    title.to_s == "" ? "##{self.id.to_s}" : title
  end

  
  def clear_values!(*args)
    options = args.extract_options!
    matched_values =  self.values.find_all_by_element_id_and_parent_id(options[:element], options[:parent])
    
    if matched_values.kind_of?(Array)
      matched_values.each { |v| v.destroy }
    elsif matched_values
      matched_values.destroy
    end
  end
  
  def set_values!(*args)
    options = args.extract_options!

    clear_values!(options)

    add_values!(options)
    
    return self
    
  end
  
  def add_values!(*args)
    
    options = args.extract_options!
    new_values = Array[*options[:values]]
    new_values.each { |nv| self.values.create!(:element => options[:element], :parent => options[:parent], :data => nv.to_s) }

    return self
  end
  
  def query_and_set_values!(*args)
    query_and_modify_values!(:set_values!, args)
  end

  def query_and_add_values!(*args)
    query_and_modify_values!(:add_values!, args)
  end
  
  def query_values(expression, *args)
    options = args.extract_options!.merge(:return => :array)
    results = query(expression, options)

    results.collect(&:values).flatten.uniq
  end

  def query(expression, *args)
    options = args.extract_options!
  
  
    locations = options.delete(:locations) || Hypath::Location.new(:element => (options.delete(:start_element) || item_type.element), :parent => (options.delete(:start_parent) || nil), :lookup => self)

    locations = Array[locations] unless locations.kind_of?(Array)
    Hypath::run_query_on({:item => self, :expression => expression, :locations => locations}.merge(options))
  end
  


  def set_values_by_query!(*args)
    
    options = args.extract_options!


    locations = options[:locations] || nil
    
    query_options = {:return => :single, :locations => locations}
    replace = options.delete(:replace) || true
    root_expression = options.delete(:root_expression) || ""
    
    options.each_pair do |expression, values|
      
      expression = root_expression.to_s + expression.to_s
      
      loc = query(expression, query_options)
      
      if loc
        clear_values!(:element => loc.element, :parent => loc.parent) if replace
        
        add_in_values_by_query(loc, values, expression, replace)
      end

    end
    
    self
  end

  protected

  def add_in_values_by_query(loc, values, expression, replace)
    case values
    when Hash
      new_value = add_in_values_by_query(loc, nil, expression, replace)
      values.each_pair do |k, v|
        new_options = {:locations => [Hypath::Location.new(:from_value => new_value, :lookup => self)], :replace => replace, :root_expression => expression}
        new_options[k] = v
        set_values_by_query!(new_options)
      end
    when Array
      values.each do |data|
        add_in_values_by_query(loc, data, expression, replace)
      end
    else
      Value.create(:element => loc.element, :parent => loc.parent, :item => self, :data => values)
    end
  end

  def query_and_modify_values!(method, args)
    options = args.extract_options!
    
    options.each_pair do |expression, values|
      self.query(expression, :return => :array).each do |location|
        self.send(method, :element => location.element, :parent => location.parent, :values => values)
      end
    end
    
    return self
  end
end
