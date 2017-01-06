class VerificationTest < ActiveRecord::Base
  
  VALID_CATEGORIES = %w{presence value count format numericality uniqueness}
  validates_inclusion_of :category, :in => VALID_CATEGORIES
  
  belongs_to :set, :class_name => "VerificationSet", :foreign_key => :set_id
  validates_presence_of :set
  
  belongs_to :element

  validate :must_have_element_or_query
  
  has_options
  
  
  
  def must_have_element_or_query
    errors.add_to_base("Must have either an element or a query") if element.nil? && query.to_s.empty?
  end
  
  
  def run(item)
    self.send("run_#{category}",values_for_item(item))
  end 
  
  def values_for_item(item)
    raise "Item passed to verification test is null" unless item
    if element
      Value.find_all_by_element_id_and_item_id(element,item.id)
    else
      item.query_values(query)
    end
  end
  
  protected
  
  
  
  def run_count
    results = []
    
    return results
  end
  
  def run_presence(values)
    results = []
    
    blank_message = message || "Please fill in #{element.name}"
    values.select { |v| v.to_s == ""}.each do |v|        
      results << ActionResult.new(self, :failure, :values => v, :message => blank_message)
    end
    
    return results
  end

  def run_value(values)
    results = []
    
    return results
    
  end
  
  def run_format(values)
    results = []
    
    return results    
  end
  
  def run_numericality(values)
    results = []
    
    values.each do |value|
      success = true
      
      if find_option_value("only_integer") == "true"
        if value.to_s =~ /\A[+-]?\d+\Z/
          success = false
          results << ActionResult.new(self, :failure, :values => value, :message => message || "#{element.name} is not an integer.")
        end
      else
        begin
          raw_value = Kernel.Float(value.to_s)
        rescue
          success = false
          results << ActionResult.new(self, :failure, :values => value, :message => message || "#{element.name} is not a number.")
        end
      end
    end
      
    return results    
  end
  
  
  def run_uniqueness(values,options)
    results = []
    
    return results    
  end
end
