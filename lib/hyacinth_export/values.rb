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
   children_by_code = Hash.new {|hash,key| hash[key] = []}
   item_values.where(parent_id: parent_id).each do |value|
    unless elements_to_codes[value.element_id]
      elements_to_codes[value.element_id] = value.element.code
    end
    
    code = elements_to_codes[value.element_id]
    children_by_code[code] << value
   end

   children_by_code.each do |code, element_values|
     tag = prefix.nil? ? code : "#{prefix}:#{code}"
     if element_values.length > 1
       element_values.each_with_index do |element_value, ix|

         ix_tag = (parent_id && !ix.zero?) ? "#{tag}-#{ix + 1}" : tag # don't index root element and don't add suffix if first element
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
