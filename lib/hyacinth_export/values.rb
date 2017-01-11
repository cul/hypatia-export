require 'ostruct'

module Values
  class << self; attr_accessor :id, :item_id, :element_id, :parent_id, :data; end
  
  ID = 0
  ITEM_ID = 1
  ELEMENT_ID = 2
  PARENT_ID = 3
  DATA = 4

  def self.value_to_row(value)
    row = 5.times.inject([]) {|m, v| m << nil }
    row[ID] = value.id
    row[ITEM_ID] = value.item_id
    row[ELEMENT_ID] = value.element_id
    row[PARENT_ID] = value.parent_id
    row[DATA] = value.data
  end

  def self.row_to_value_struct(row)
    OpenStruct.new(id: row[ID], item_id: row[ITEM_ID],
                   element_id: row[ELEMENT_ID], parent_id: row[PARENT_ID],
                   data: row[DATA])
  end

  def self.accumulate(prefix,parent_id,elements_to_codes,item_values,value_map)
   children_by_element = Hash.new {|hash,key| hash[key] = []}
   item_values.each do |value|
     next unless value.parent_id == parent_id
     children_by_element[value.element_id] << value
   end
   children_by_element.each do |element_id, element_values|
     # load missing elements if possible
     unless elements_to_codes.has_key? element_id.to_s
      element = Element.find(element_id.to_i)

      elements_to_codes[element.id.to_s] = element.code
      elements = Element.find(*element.nested_children_ids)
      elements = [elements] unless elements.respond_to? :each
      elements.each do |element|
        elements_to_codes[element.id.to_s] = element.code
      end
     end
     code = elements_to_codes[element_id.to_s]
     if code.nil?
       puts "no code for #{element_id}"
       next
     end
     tag = prefix.nil? ? code : "#{prefix}:#{code}"
     if element_values.length > 1
       element_values.each_with_index do |element_value, ix|
         ix_tag = parent_id ? "#{tag}-#{ix + 1}" : tag # don't index root element
         if element_value.data
           value_map[ix_tag] = element_value.data
         end
         accumulate(ix_tag,element_value.id,elements_to_codes,item_values,value_map)
       end
     else
       element_value = element_values[0]
       next unless element_value
       if element_value.data
         value_map[tag] = element_value.data
       end
       accumulate(tag,element_value.id,elements_to_codes,item_values,value_map)
     end
   end
   value_map
  end
end
