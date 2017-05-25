require 'hypatia_export'
require 'fedora_helper'

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

    # Remove items that aren't being exported.
    ignore = HypatiaExport.do_not_export
    items = items.reject { |i| ignore.include?(i.id) }

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

  task :export_many_templates => :environment do
    # ENV['in_batches'] = 'true'

    ['33', '34', '32', '31', '29', '23', '21', '20', '19', '18', '17'].each do |num|
      ENV['item_type'] = num
      Rake::Task['hypatia:export_template'].execute
    end
  end

  desc 'retrieve all items that are being exported without pids'
  task :items_without_pids => :environment do
    filename = HypatiaExport.items_without_pids
    puts "Output csv at #{filename}"
  end

  desc 'check for duplicate pids through out all the exports'
  task :duplicate_pids => :environment do
    # All start from the same google drive folder
    # /Users/cmg2228/Google Drive/AC4/Hypatia to Hyacinth Migration/Export CSVs

    filepaths = %w(
      acDissertation/acDissertation-export-from-hypatia.csv
      acETD/acETD-1-export-from-hypatia.csv
      acETD/acETD-2-export-from-hypatia.csv
      acETD/acETD-3-export-from-hypatia.csv
      acETD/acETD-4-export-from-hypatia.csv
      acETD/acETD-5-export-from-hypatia.csv
      acETD/acETD-6-export-from-hypatia.csv
      acETD/acETD-7-export-from-hypatia.csv
      acETD/acETD-8-export-from-hypatia.csv
      acETD/acETD-9-export-from-hypatia.csv
      acMonograph/acMonograph-1-export-from-hypatia.csv
      acMonograph/acMonograph-2-export-from-hypatia.csv
      acMonograph/acMonograph-3-export-from-hypatia.csv
      acMonograph/acMonograph-4-export-from-hypatia.csv
      acMonograph/acMonograph-5-export-from-hypatia.csv
      acMonograph/acMonograph-6-export-from-hypatia.csv
      acMonograph/acMonograph-7-export-from-hypatia.csv
      acMonograph/acMonograph-8-export-from-hypatia.csv
      acMonograph/acMonograph-9-export-from-hypatia.csv
      acMonograph/acMonograph-10-export-from-hypatia.csv
      acMonograph/acMonograph-11-export-from-hypatia.csv
      acMonograph/acMonograph-12-export-from-hypatia.csv
      acMonographPart/acMonographPart-1-export-from-hypatia.csv
      acMonographPart/acMonographPart-2-export-from-hypatia.csv
      acPubArticle/acPubArticle-hyacinth-import-170410.csv
      acPubArticle10/acPubArticle10-hyacinth-import-170315.csv
      acSerialPart/acSerialPart-1-export-from-hypatia.csv
      acSerialPart/acSerialPart-2-export-from-hypatia.csv
      acSerialPart/acSerialPart-3-export-from-hypatia.csv
      acSerialPart/acSerialPart-4-export-from-hypatia.csv
      acSerialPart/acSerialPart-5-export-from-hypatia.csv
      acSerialPart/acSerialPart-6-export-from-hypatia.csv
      acSerialPart/acSerialPart-7-export-from-hypatia.csv
      acSerialPart/acSerialPart-8-export-from-hypatia.csv
      acSerialPart/acSerialPart-9-export-from-hypatia.csv
      acSerialPart/acSerialPart-10-export-from-hypatia.csv
      acSerialPart/acSerialPart-11-export-from-hypatia.csv
      acSerialPart/acSerialPart-12-export-from-hypatia.csv
      acSerialPart/acSerialPart-13-export-from-hypatia.csv
      acSerialPart/acSerialPart-14-export-from-hypatia.csv
      acSerialPart/acSerialPart-15-export-from-hypatia.csv
      acSerialPart/acSerialPart-16-export-from-hypatia.csv
      acSerialPart/acSerialPart-17-export-from-hypatia.csv
      acSerialPart/acSerialPart-18-export-from-hypatia.csv
      acSerialPart/acSerialPart-19-export-from-hypatia.csv
      acTypeAV/acTypeAV-hyacinth-import-170406.csv
      acTypeBook/acTypeBook-hyacinth-import-for-review.csv
      acTypeBook10/acTypeBook10-hyacinth-import-170313.csv
      acTypeBookChapter/acTypeBookChapter-hyacinth-import-for-review.csv
      acTypeBookChapter10/acTypeBookChapter10-hyacinth-import-170413.csv
      acTypeUnpubItem/acTypeUnpubItem-hyacinth-import-for-review.csv
      acTypeUnpubItem10/acTypeUnpubItem10-hyacinth-import-170523.csv
      acWP/acWP-export-from-hypatia.csv
      acWP10/acWP10-hyacinth-import-170502.csv
      acWebpagePart/acWebpagePart-export-from-hypatia.csv
    )

    filepaths = filepaths.map do |path|
      File.expand_path(File.join('~', 'Google Drive', 'AC4', 'Hypatia to Hyacinth Migration', 'Export CSVs', path))
    end
    HypatiaExport.find_duplicate_pids(filepaths)
  end

  desc 'make assets active'
  task :make_asset_active => :environment do
    if ENV['filename']
      filename = ENV['filename']
    else
      puts "pass filename=filename"
    end

    CSV.foreach(filename, headers: true) do |row|
      # FedoraHelper.make_asset_active(row['asset'], 'Making assets active')
      puts "#{row['asset']} now active"
    end
  end

  desc 'retrieve items with inactive assets'
  task :inactive_assets_csv => :environment do
    fconfig = Rails.application.config_for(:fedora)
    repo = Rubydora.connect(url: fconfig['url'], user: fconfig['user'], password: fconfig['password'])
    ri_query = "select $parent $asset $metadata from <#ri> "\
               "where $asset <info:fedora/fedora-system:def/model#state> <info:fedora/fedora-system:def/model#Inactive> "\
               "and $asset <http://purl.oclc.org/NET/CUL/memberOf> $parent "\
               "and $metadata <http://purl.oclc.org/NET/CUL/metadataFor> $parent"

    response = repo.risearch(ri_query, format: 'json', lang: 'itql')
    inactive_assets = JSON.parse(response.body)['results']

    # Remove items that aren't being exported.
    ignore = HypatiaExport.do_not_export

    inactive_assets.reject! { |r| ignore.include?(r['parent'])}

    CSV.open(File.join('tmp', 'data', 'inactive_assets.csv'), 'w', encoding: 'UTF-8') do |csv|
      csv.add_row ['hypatia id', 'aggregator', 'asset', 'access restriction', 'embargo date']
      inactive_assets.each do |r|
        # Retrieve hypatia id.
        mpid = r['metadata'].gsub("info:fedora/", "")
        uri = URI("#{fconfig['url']}/objects/#{mpid}/datastreams/CONTENT/content")
        content = Net::HTTP.get(uri)
        doc = Nokogiri::XML(content)
        hypatia_id = doc.at_css("recordInfo > recordIdentifier").text

        access_restriction, embargo_date = nil, nil
        if e = doc.at_css("accessCondition[type=\"restriction on access\"]")
          if e.children.count == 1 && e.child.text?
            access_restriction = e.text
          elsif embargo_date = e.at_css("extension > free_to_read[start_date]")
            embargo_date = embargo_date.values.first
          end
        end

        csv.add_row([
          hypatia_id,
          r['parent'].gsub("info:fedora/", ""),
          r['asset'].gsub("info:fedora/", ""),
          access_restriction,
          embargo_date
        ])
      end
    end
  end
end
