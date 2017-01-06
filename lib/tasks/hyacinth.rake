require 'csv'
namespace :hyacinth do
  desc "export data for hyacinth"
  task :export => :environment do
    # parse the element paths & populate the id-to-code hash
    elements_to_codes = {}
    elements_hierarchy = Hash.new {|hash,key| hash[key] = Hash.new &hash.default_proc }
    open("test/data/elements.csv") do |blob|
      blob.each do |line|
        line.strip!
        values = line.parse_csv
        current = elements_hierarchy
        (0...values.length/3).each do |ix|

          code = values[ix*3]
          id = values[(ix*3) + 1]
          pos = values[(ix*3) + 2].to_i
          next if code == '' && id == ''
          id = id.to_i
          elements_to_codes[id] = code
          current = current[id]
        end
      end
    end
    puts elements_to_codes.inspect
    puts elements_hierarchy.inspect

    type = ItemType.find(41)
    # item = Item.find(4066)
    header_line = "id,item_id,element_id,parent_id,data,created_at,updated_at"
    headers = header_line.split(',').collect { |hdr| hdr.to_sym }
    open('test/data/values.csv','w') do |out|
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
  task :export_values => :export do
    # parse the element paths & populate the id-to-code hash
    elements_to_codes = {}
    open("test/data/elements.csv") do |blob|
      blob.each do |line|
        line.strip!
        values = CSV.parse_line(line)
        code = values[3]
        id = values[0]
        elements_to_codes[id] = code
      end
    end

    items = {'2240' => 'ac:128939', '3063' => 'ac:130062', '3064' => 'ac:130066'}
    elements = CSV.read('test/data/elements.csv')
    # values for 3 items, cached
    values = CSV.read('test/data/values.csv')

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

    headers = []
    value_maps = items.collect do |item_id, pid|
      item_values = values.select { |value| value[Values.item_id] == item_id }
      value_map = Values.accumulate(nil,nil,elements_to_codes,item_values,{ '_pid' => pid })
      headers += value_map.keys.sort
      value_map
    end
    headers.uniq!
    headers.sort!
    puts CSV.generate_line(headers)
    value_maps.each do |value_map|
      row_values = headers.collect { |tag| value_map[tag] }
      puts CSV.generate_line(row_values)
    end
  end
end