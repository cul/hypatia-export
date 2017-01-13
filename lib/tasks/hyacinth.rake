require 'csv'
require 'hyacinth_export'
require 'hyacinth_export/map_headers'

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
    HyacinthExport.export_fields(41) #4066

  end

  task :export_values => :environment do
    if ENV['items']
      item_ids = ENV['items'].split(',').map(&:to_i)
      puts "item_ids: #{item_ids.inspect}"
      items = Item.find(*item_ids)
    elsif ENV['item_type']
      limit = ENV['limit'] ? ENV['limit'].to_i : 10
      items = Item.where(item_type_id: ENV['item_type'].to_i).limit(limit)
    else
      puts "pass items=ID,ID,ID... or item_type=ID [limit=LIMIT]"
    end

    HyacinthExport.export_values(items) if items
  end

  task :export_from_acpubarticle10 => :environment do
    HyacinthExport::MapHeaders.from_acpubarticle10
  end
end
