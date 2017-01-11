class Element < ActiveRecord::Base
  CATEGORY_TYPES = %w{Field Template}
  FIELD_TYPES = %w{text textarea date datetime checkbox select userpicker file handle ezid}
  VALID_CODE = /^[A-Za-z_:][A-Za-z0-9\.-_:]+$/
  INVALID_CODE_MSG = "must start with a letter or _, and include only letters, digits, periods, underscores, and dashes."

  include Optionable

  has_many :children, :through => :children_links, :order => "position"
  has_many :children_links, :class_name => "ElementLink", :foreign_key => :parent_id, :dependent => :destroy, :order => "position"
  
  has_many :parents, :through => :parent_links, :order => "position"
  has_many :parent_links, :class_name => "ElementLink", :foreign_key => :child_id, :dependent => :destroy, :order => "position"

  has_options
  accepts_nested_attributes_for :options, :allow_destroy => true, :reject_if => proc { |attrs| attrs.all? {|k,v| v.blank? }}

  validates_inclusion_of :category, :in => CATEGORY_TYPES
  validates_inclusion_of :field_type, :in => FIELD_TYPES, :allow_nil => true

  validates_numericality_of :minimum, :only_integer => true, :greater_than_or_equal_to => 0
  validates_numericality_of :maximum, :only_integer => true, :allow_nil => true, :greater_than => 0

  validates_associated :children_links, :parent_links

  validates_presence_of :name
    
  validates_length_of :code, :within => 2..25
  validates_format_of :code, :with => VALID_CODE, :message => INVALID_CODE_MSG
  
  
  
  has_many :item_types
  has_many :values, :dependent => :destroy

  
  validate :no_circular_reference
  validate :field_must_have_type

  def display_label
    display_name.to_s == "" ? name : display_name
  end
  
  def to_s
    "#{category} - #{name}"
  end
  
  def ids_not_to_add
    Element.find_all_by_category_and_id("Template",self.nested_children_ids, :select => "elements.id").collect(&:id) | ElementLink.find_all_by_parent_id(self.id).collect(&:child_id)
  end
  
  def nested_children_ids


    Element.find_children_ids_of([self.id], self.id)
  end
    
  
  
  def nested_clone
    new_element = self.clone
    new_element.save!
    self.options.each { |opt| new_element.options << opt.clone }
    self.children.each { |child| new_element.children << child.nested_clone}
    
    new_element.save!
    
    return new_element
  end
  
  def nested_destroy
    self.children.each { |child| child.nested_destroy }
    self.destroy
  end
  
  def nested_codes
    if self.children.empty?
      [code]
    else
      self.children.collect { |child| child.nested_codes.collect { |child_code| code + "/" + child_code} }.flatten
    end
  end
  
  def partial(type = :class)
    result = case type
    when :class
      category.to_s.downcase

    when :category
      category == "Field" ? "field_#{field_type}" : "template"
    
    when :entry
      category == "Field" ? "field_entry" : "template_entry"
    end
     
    "/items/#{result}"
  end
  
  
  def generate_select_options
    select_options = []
    if category == "Field" && field_type.in?("select","userpicker")
      if field_type == "userpicker"
        select_options= User.find(:all).collect {|user| ["#{user.uid} - #{user.name}", user.id.to_s] }
      else
        vocab = Vocabulary.find_by_id(find_option_value(:vocabulary))
        
        if vocab
          select_options = vocab.base_members.collect { |mem| [mem.name, mem.member_value]}
        else
          raise "Vocabulary not found for element #{self.id}"
        end
      end   
    else
      raise "Element not labeled as select or userpicker field asked to generate select tag options."
    end
    
    select_options = [["",""]] + select_options if find_option_value(:include_blank) == "1"
    
    select_options
    
    
  end
  
  def infinite?
    self.maximum.nil?
  end
  
  def multiple?
    self.infinite? || (self.maximum > 1)
  end

  def flexible?
    self.infinite? || (self.maximum >= 1 && self.maximum > self.minimum)
  end
  
  def to_xml(opts = {})
    opts[:indent] ||= 2
    xml = opts[:builder] ||= Builder::XmlMarkup.new(:indent => opts[:indent])
    xml.instruct! unless opts[:skip_instruct]
    item = opts[:item]
    
    if opts[:style] == :data
      parent_id = opts[:parent_id]
      attributes = {:category => category}
      attributes.merge(:multiple => multiple?) if category == "Field"
      xml.tag!(code, attributes) do
        unless (values = item.find_oriented_values(self.id, parent_id)).empty?
          values.each do |value|
            if self.category == "Template"
              children.each do |child|
                child.to_xml(:builder => xml, :skip_instruct => true, :item => item, :parent_id => value.id, :value => value, :style => :data)
              end
            else
              if multiple?
                xml.value value.data.to_s
              else
                xml.text! value.data.to_s
              end
            end
          end
        end
      end 
    end
  end
  
  def quantity_to_s
    case maximum
    when 1
      minimum == 0 ? "optional" : "required"
    when nil
      minimum == 0 ? "0 or more" : "1 or more"
    else
      "#{minimum}-#{maximum}"  
    end
  end
    
  def year_range
    if category == "Field" || field_type.in?("date", "datetime")
      start_year = find_option_value(:start_year) || 1900
      end_year = find_option_value(:end_year) || 2020
      year_range = (start_year.to_i)..(end_year.to_i)
    else
      raise "Year range asked for non date/datetime field."
    end
  end
  

 def self.find_children_ids_of(all_ids, *element_ids)
    child_ids = ElementLink.find_all_by_parent_id(element_ids).collect(&:child_id).uniq
    new_to_test = child_ids - all_ids
     
    all_ids = Element.find_children_ids_of(all_ids | child_ids, *new_to_test) unless new_to_test.empty?
     
    all_ids
  end
  
  def self.root_templates
    child_templates =  ElementLink.find(:all, :select => "child_id").collect(&:child_id).uniq

    Element.all_templates.reject { |e| e.id.in?(child_templates)}
  end

  def self.sub_templates
    child_templates =  ElementLink.find(:all, :select => "child_id").collect(&:child_id).uniq

    Element.all_templates.select { |e| e.id.in?(child_templates)}
  end

  
  def self.all_templates
    Element.find_all_by_category("template", :order => "name")
  end

  private
  
  #TODO: needs to check all the way up a given tree.
  def no_circular_reference

  end
  
  
  
  def field_must_have_type
    errors.add_to_base("Elements that are of category Field must have a field type") unless category == "Template" || field_type.in?(FIELD_TYPES)
  end

end

