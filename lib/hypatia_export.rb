require 'csv'
require 'hypatia_export/values'

module HypatiaExport
  DO_NOT_EXPORT = File.expand_path(File.join('~', 'Google Drive', 'AC4', 'Hypatia to Hyacinth Migration', 'Export CSVs', 'do_not_export.csv'))

  def self.items_without_pids
    filename = File.join('tmp', 'data', 'items_without_pids.csv')
    ignore = do_not_export

    CSV.open(filename, 'w', encoding: 'UTF-8') do |csv|
      Item.all.find_each do |i|
        next if ignore.include?(i.id) || !i.fedora_pid.blank?
        csv.add_row [i.fedora_pid]
      end
    end
    filename
  end

  def self.export_fields(item_type_id) # Exports all fields for the same ItemType
    type = ItemType.find(item_type_id) # Find a class of item (journal article, image, Oral History Object).
    # item = Item.find(4066)
    header_line = "id,item_id,element_id,parent_id,data,created_at,updated_at"
    headers = header_line.split(',').collect { |hdr| hdr.to_sym }

    ::CSV.open('tmp/data/values.csv','w') do |csv|
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
      end
    end
  end

  def self.export_values(items, filename)
    elements_to_codes = HypatiaExport.elements_to_codes

    # Remove items that aren't being exported.
    ignore = do_not_export
    items = items.reject { |i| ignore.include?(i.id) }

    headers = []
    value_maps = items.collect do |item|
      value_map = Values.accumulate(nil,nil,elements_to_codes,item.values,{ '_pid' => item.fedora_pid, '_hypatia_id' => item.id })
      headers += value_map.keys.sort
      value_map
    end
    headers.uniq!
    headers.sort!

    ::CSV.open(filename, 'w', encoding: 'UTF-8') do |csv|
      csv.add_row(headers)
      value_maps.each do |value_map|
        row_values = headers.collect { |tag| value_map[tag] }
        csv.add_row(row_values)
      end
    end
  end

  ## Helpers

  # Returns array of hypatia ids that should not be exported
  def self.do_not_export
    CSV.read(DO_NOT_EXPORT).drop(1).map(&:first).map(&:to_i)
  end

  # parse the element paths & populate the id-to-code hash
  def self.elements_to_codes
    elements_to_codes = {}
    open("fixtures/data/elements.csv") do |blob|
     blob.each do |line|
       line.strip!
       values = ::CSV.parse_line(line)
       code = values[3]
       id = values[0]
       elements_to_codes[id] = code
     end
    end
    elements_to_codes
  end
end
