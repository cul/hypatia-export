require 'hypatia_export'

namespace :hypatia do
  desc 'export given items to a csv'
  task :export => :environment do
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
    HypatiaExport.export_values(items, filename) if items
  end

  desc 'export an entire template to a csv(s)'
  task :export_template => :environment do
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

    code = ItemType.find(item_type).element.code
    if in_batches
      items.each_slice(500).with_index do |group, idx|
        filename = File.join(Rails.root, 'tmp', 'data', "#{code}-#{idx+1}-export-from-hypatia.csv")
        HypatiaExport.export_values(group, filename)
      end
    else
      filename = File.join(Rails.root, 'tmp', 'data', "#{code}-export-from-hypatia.csv")
      HypatiaExport.export_values(items, filename)
    end
  end

  desc 'retrieve all items that are being exported without pids'
  task :items_without_pids => :environment do
    filename = HypatiaExport.items_without_pids
    puts "Output csv at #{filename}"
  end

  desc 'retrieve all items that are embargoed and do not have pids'
  task :embargoed_items_without_pids => :environment do
    puts 'not implemented'
  end
end
