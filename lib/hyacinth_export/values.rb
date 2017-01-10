module Values
  class << self; attr_accessor :id, :item_id, :element_id, :parent_id, :data; end
  
  @id = 0
  @item_id = 1
  @element_id = 2
  @parent_id = 3
  @data = 4

  def self.accumulate(prefix,parent_id,elements_to_codes,item_values,value_map)
   children_by_element = Hash.new {|hash,key| hash[key] = []}
   item_values.each do |value|
     next unless value[Values.parent_id] == parent_id
     children_by_element[value[Values.element_id]] << value
   end
   children_by_element.each do |element, element_values|
     code = elements_to_codes[element]
     if code.nil?
       puts "no code for #{element}"
     end
     tag = prefix.nil? ? code : "#{prefix}:#{code}"
     if element_values.length > 1
       element_values.each_with_index do |element_value, ix|
         ix_tag = parent_id ? "#{tag}-#{ix + 1}" : tag # don't index root element
         if element_value[Values.data]
           value_map[ix_tag] = element_value[Values.data]
         end
         accumulate(ix_tag,element_value[Values.id],elements_to_codes,item_values,value_map)
       end
     else
       element_value = element_values[0]
       next unless element_value
       if element_value[Values.data]
         value_map[tag] = element_value[Values.data]
       end
       accumulate(tag,element_value[Values.id],elements_to_codes,item_values,value_map)
     end
   end
   value_map
  end
end
