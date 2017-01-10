require 'csv'
require 'hyacinth_export/values'

module HyacinthExport
  def self.export; end

  def self.export_values
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
    puts CSV.generate_line(headers)
    value_maps.each do |value_map|
      row_values = headers.collect { |tag| value_map[tag] }
      puts CSV.generate_line(row_values)
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
