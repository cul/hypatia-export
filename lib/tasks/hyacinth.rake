require 'csv'
require 'hyacinth_export'

namespace :hyacinth do
  desc "export data for hyacinth"
  task :export => :environment do
    # parse the element paths & populate the id-to-code hash
    # elements_to_codes = {}
    # elements_hierarchy = Hash.new {|hash,key| hash[key] = Hash.new &hash.default_proc }
    # open("fixtures/data/elements.csv") do |blob|
    #   blob.each do |line|
    #     line.strip!
    #     values = line.parse_csv
    #     current = elements_hierarchy
    #     (0...values.length/3).each do |ix|
    #
    #       code = values[ix*3]
    #       id = values[(ix*3) + 1]
    #       pos = values[(ix*3) + 2].to_i
    #       next if code == '' && id == ''
    #       id = id.to_i
    #       elements_to_codes[id] = code
    #       current = current[id]
    #     end
    #   end
    # end
    # puts elements_to_codes.inspect
    # puts elements_hierarchy.inspect

    type = ItemType.find(41)
    # item = Item.find(4066)
    header_line = "id,item_id,element_id,parent_id,data,created_at,updated_at"
    headers = header_line.split(',').collect { |hdr| hdr.to_sym }
    open('tmp/data/values.csv','w') do |out|
      out.print(header_line)
      Item.where(:conditions => ["id IN (?)" , [2240,3063,3064]], :limit => 3).each do |item|
        value_ids_by_element = Hash.new {|h,k| h[k] = []}
        values_by_id = {}
        root = nil
        item.values.each do |value|
          values_by_id[value.id] = value
          value_ids_by_element[value.element_id] << value.id
          if value.element_id == type.element_id
            root = value
          end
          fields = headers.map { |hdr| item.send hdr }
          out.print CSV.generate_line(fields)
        end
        values_hierarchy = Hash.new {|hash,key| hash[key] = Hash.new &hash.default_proc }
        current = values_hierarchy[root.id]
        def children(values, map, parent_id)
          values.select {|v| v.parent_id == parent_id }.each do |v|
            children(values, map[v.id], v.id)
          end
        end
        children(values, current, root.id)
        puts values_hierarchy.inspect

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

  task :export_values => :environment do
    HyacinthExport.export_values
  end
end
