require 'csv'
require 'hyacinth_export/values'

module HyacinthExport
  def self.export_fields(item_type_id) # Exports all fields for the same ItemType
    type = ItemType.find(item_type_id) # Find a class of item (journal article, image, Oral History Object).
    # item = Item.find(4066)
    header_line = "id,item_id,element_id,parent_id,data,created_at,updated_at"
    headers = header_line.split(',').collect { |hdr| hdr.to_sym }

    CSV.open('tmp/data/values.csv','w') do |csv|
      csv.add_row(header_line.split(","))
      Item.where("id IN (?)", [2240,3063,3064]).limit(3).each do |item|
        value_ids_by_element = Hash.new {|h,k| h[k] = []}
        values_by_id = {}
        root = nil
        item.values.each do |value|
          values_by_id[value.id] = value
          value_ids_by_element[value.element_id] << value.id
          if value.element_id == type.element_id
            root = value
          end
          fields = headers.map { |hdr| value.send hdr }
          csv.add_row(fields)
        end

        # Gets the relationships between the different values attached to this item.
        #
        # values_hierarchy = Hash.new {|hash,key| hash[key] = Hash.new &hash.default_proc }
        # current = values_hierarchy[root.id]
        # def children(values, map, parent_id)
        #   values.select {|v| v.parent_id == parent_id }.each do |v|
        #     children(values, map[v.id], v.id)
        #   end
        # end
        # children(values, current, root.id)
        # puts values_hierarchy.inspect

        # Hyacinth format is _?[a-z_]+(-\d)? for element
        # leading underscore is for reserved tag names
        # -\d is for multiple values that need to be collected
        # (:) to separate hierarchy
        # .string_key for controlled values
        # .uri and .value for URI values/labels
        # nothing for plain old data
      end
    end
  end

  # Exporting with cached values. Does not require a db connection.
  def self.export_values #export_records
    elements_to_codes = elements_to_codes

    items = {'2240' => 'ac:128939', '3063' => 'ac:130062', '3064' => 'ac:130066'}
    # values for 3 items, cached
    values = CSV.read('fixtures/data/values.csv')

    elements_to_codes = HyacinthExport.elements_to_codes

    headers = []
    value_maps = items.collect do |item_id, pid|
      item_values = values.select { |value| value[Values.item_id] == item_id }
      value_map = Values.accumulate(nil,nil,elements_to_codes,item_values,{ '_pid' => pid })
      headers += value_map.keys.sort
      value_map
    end
    headers.uniq!
    headers.sort!
    CSV.open('tmp/data/test-export-values.csv','w') do |csv|
      csv.add_row(headers)
      value_maps.each do |value_map|
        row_values = headers.collect { |tag| value_map[tag] }
        csv.add_row(row_values)
      end
    end
  end

  ## Helpers

  # parse the element paths & populate the id-to-code hash
  def self.elements_to_codes
    elements_to_codes = {}
    open("fixtures/data/elements.csv") do |blob|
     blob.each do |line|
       line.strip!
       values = CSV.parse_line(line)
       code = values[3]
       id = values[0]
       elements_to_codes[id] = code
     end
    end
    elements_to_codes
  end
end
