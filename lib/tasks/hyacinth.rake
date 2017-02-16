require 'csv'
require 'hyacinth_export'
require 'hyacinth_export/map_headers'

namespace :hyacinth do
  desc "export data for hyacinth"
  task :export => :environment do
   puts 'not yet implemented'
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
      in_batches = (ENV['in_batches'] == 'true') ? true : false
      items = if limit
                Item.where(item_type_id: item_type).limit(limit)
              else
                Item.where(item_type_id: item_type)
              end
    else
      puts "pass item_type=ID [limit=LIMIT] [in_batches=true]"
    end

    # Remove items that should be ignored.
    do_not_export_filepath = File.expand_path(File.join('~', 'Google Drive', 'AC4', 'Hypatia to Hyacinth Migration', 'Export CSVs', 'do_not_export.csv'))
    ignore = ::CSV.read(do_not_export_filepath).drop(1).map(&:first).map(&:to_i)
    items = items.reject { |i| ignore.include?(i.id) }

    code = ItemType.find(item_type).element.code
    if in_batches
      items.each_slice(500).with_index do |group, idx|
        filename = File.join(Rails.root, 'tmp', 'data', "#{code}-#{idx+1}-export-from-hypatia.csv")
        HyacinthExport.export_values(group, filename)
      end
    else
      filename = File.join(Rails.root, 'tmp', 'data', "#{code}-export-from-hypatia.csv")
      HyacinthExport.export_values(items, filename)
    end
  end

  desc 'convert hypatia csv to hyacinth csv'
  task :create_hyacinth_csv => :environment do
    if ENV['item_type_code']
      code = ENV['item_type_code']
      filename = ENV['filename'] || File.join(Rails.root, 'tmp', 'data', "#{code}-export-from-hypatia.csv")
      # Raise error if filename does not contain 'export-from-hypatia'
    else
      puts "pass item_type_code=code [filename=filename]"
    end

    HyacinthExport::MapHeaders.send("from_#{code.downcase}", filename, filename.gsub('export-from-hypatia', 'hyacinth-import-for-review'))
  end
end
