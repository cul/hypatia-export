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

    filename = File.join(Rails.root, 'tmp', 'data', "individual-item-export-from-hypatia.csv")
    items = [items] unless items.respond_to? :each
    HyacinthExport.export_values(items, filename) if items
  end

  desc 'export template from Hypatia'
  task :export_from_hypatia => :environment do
    if ENV['item_type']
      limit = ENV['limit'] ? ENV['limit'].to_i : nil
      item_type = ENV['item_type'].to_i
      items = if limit
                Item.where(item_type_id: item_type).limit(limit)
              else
                Item.where(item_type_id: item_type)
              end
    else
      puts "pass item_type=ID [limit=LIMIT]"
    end

    code = ItemType.find(item_type).element.code
    filename = File.join(Rails.root, 'tmp', 'data', "#{code}-export-from-hypatia.csv")
    HyacinthExport.export_values(items, filename)
  end

  desc 'convert hypatia csv to hyacinth csv'
  task :create_hyacinth_csv => :environment do
    if ENV['item_type_code']
      code = ENV['item_type_code']
      filename = ENV['filename'] || File.join(Rails.root, 'tmp', 'data', "#{code}-export-from-hypatia.csv")
    else
      puts "pass item_type_code=code [filename=filename]"
    end

    HyacinthExport::MapHeaders.send("from_#{code.downcase}", filename)
  end
end
