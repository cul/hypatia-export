require 'csv'
require 'hyacinth_mapping'

namespace :hyacinth do
  desc 'convert hypatia csv to hyacinth csv'
  task :create_csv_for => :environment do
    if ENV['item_type_code']
      code = ENV['item_type_code']
      filename = ENV['filename'] || "#{code}-export-from-hypatia.csv"
      filename = File.join(Rails.root, 'tmp', 'data', filename)
      # Raise error if filename does not contain 'export-from-hypatia'
    else
      puts "pass item_type_code=code [filename=filename]"
    end

    HyacinthMapping.send("from_#{code.downcase}", filename, filename.gsub('export-from-hypatia', 'hyacinth-import-for-review'))
  end

  task :create_all_csvs => :environment do
    directory = File.join(Rails.root, 'tmp', 'data')

    # acEDT
    (1..9).each do |num|
      filename = File.join(directory, "acETD-#{num}-export-from-hypatia.csv")
      HyacinthMapping.from_acetd(filename, filename.gsub('export-from-hypatia', 'hyacinth-import-for-review'))
    end
  end

  task :asset_csv => :environment do
    if ENV['filename']
      aggregator_csv = ENV['filename']
    else
      puts "pass filename=filename"
    end

    # Get list of pids.
    aggregators = []
    CSV.foreach(aggregator_csv, headers: true) do |row|
      aggregators << row['_pid'] ## NEED TO USE COLUMN NAME
    end

    fconfig = Rails.application.config_for(:fedora)
    repo = Rubydora.connect(url: fconfig['url'], user: fconfig['user'], password: fconfig['password'])

    # Query Fedora for assets
    headers = [
      '_pid', '_digital_object_type.string_key', '_parent_digital_objects-1.pid',
      '_project.string_key', 'title-1:title_sort_portion'
    ]
    assets_to_aggregators = []
    aggregators.each do |agr_pid|
      ri_query = "select $member $title from <#ri> where $member <http://purl.oclc.org/NET/CUL/memberOf> <fedora:#{agr_pid}> and $member <info:fedora/fedora-system:def/model#label> $title"
      response = repo.risearch(ri_query, format: 'json', lang: 'itql')
      assets = JSON.parse(response.body)['results']
      assets.each do |asset|
        pid = asset['member'].gsub('info:fedora/', '')
        title = asset['title']
        assets_to_aggregators << [pid, 'asset', agr_pid, 'academic_commons', title]
      end
    end

    asset_csv = aggregator_csv.sub('hyacinth-import-for-review', 'asset-to-aggregators')

    # Create aggregator to asset csv.
    CSV.open(asset_csv, "w") do |csv|
      csv.add_row(headers)
      assets_to_aggregators.each { |row| csv.add_row(row) }
    end
  end
end
