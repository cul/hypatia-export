require 'csv'
require 'hyacinth_mapping'

namespace :hyacinth do
  desc 'convert hypatia csv to hyacinth csv'
  task :create_csv_for => :environment do
    if ENV['item_type_code']
      code = ENV['item_type_code']
      filename = ENV['filename'] || "#{code}-export-from-hypatia.csv"
      # Raise error if filename does not contain 'export-from-hypatia'
    else
      puts "pass item_type_code=code [filename=filename]"
    end

    gdrive_export = File.expand_path(File.join('~', 'Google Drive', 'AC4', 'Hypatia to Hyacinth Migration', 'Export CSVs', code, filename))
    mapped_file = File.join(Rails.root, 'tmp', 'data', filename.gsub('export-from-hypatia', 'hyacinth-import-for-review'))

    HyacinthMapping.send("from_#{code.downcase}", gdrive_export, mapped_file)
  end

  task :create_many_csvs => :environment do
    (1..19).each do |num|
      ENV['item_type_code'] = 'acSerialPart'
      ENV['filename'] = "acSerialPart-#{num}-export-from-hypatia.csv"
      puts "acSerialPart-#{num}-export-from-hypatia.csv"
      Rake::Task['hyacinth:create_csv_for'].execute
    end

    # (1..12).each do |num|
    #   ENV['item_type_code'] = 'acMonograph'
    #   ENV['filename'] = "acMonograph-#{num}-export-from-hypatia.csv"
    #   puts "acMonograph-#{num}-export-from-hypatia.csv"
    #   Rake::Task['hyacinth:create_csv_for'].execute
    # end

    # (1..9).each do |num|
    #   ENV['item_type_code'] = 'acETD'
    #   ENV['filename'] = "acETD-#{num}-export-from-hypatia.csv"
    #   puts "acETD-#{num}-export-from-hypatia.csv"
    #   Rake::Task['hyacinth:create_csv_for'].execute
    # end
  end

  task :decode_html_entities do
    if ENV['filepath']
      filepath = ENV['filepath']
    else
      puts "pass filepath=filepath"
    end

    require 'htmlentities'
    coder = HTMLEntities.new

    array_of_arrays = ::CSV.read(filepath, encoding: 'UTF-8')
    decoded_arrays = array_of_arrays.each_with_index.map do |array, i|
      if i.zero? # Ignoring header
        array
      else
        array.map { |cell| coder.decode(cell) }
      end
    end
    # ignore header column
    # go through every cell and run through html entities decoder
    CSV.open(filepath, "w+") do |csv|
      decoded_arrays.each do |r|
        csv.add_row r
      end
    end
  end

  task :publish_csv => :environment do
    if ENV['template'] && ENV['files']
      template = ENV['template']
      files = ENV['files']
    else
      puts Rainbow("pass template=TEMPLATE_CODE files=FILENAME1,FILENAME2").red
    end

    GOOGLE_DRIVE_FOLDER = File.expand_path(File.join('~', 'Google Drive', 'AC4', 'Hypatia to Hyacinth Migration', 'Export CSVs'))

    DO_NOT_PUBLISH = File.join(GOOGLE_DRIVE_FOLDER, 'do_not_publish.csv')
    do_not_publish = CSV.read(DO_NOT_PUBLISH, headers: true ).map { |r| r['_pid'] }

    pids = files.split(',').map do |file|
      filename = File.join(GOOGLE_DRIVE_FOLDER, template, file)
      CSV.read(filename, headers: true).map { |r| r['_pid'] }.compact
    end.flatten

    # Removing pids that shouldn't be published and displaying message.
    pids = pids.delete_if do |p|
      if do_not_publish.include?(p)
        puts Rainbow("NOT PUBLISHING #{p}").yellow
        true
      else
        false
      end
    end

    # Write out CSV to google_drive_folder/template/PUBLISH-template.csv
    filename = File.join(GOOGLE_DRIVE_FOLDER, template, "PUBLISH-#{template}.csv")
    CSV.open(filename, 'w', encoding: 'UTF-8') do |csv|
      csv.add_row ['_pid', '_publish_targets-1.string_key', '_publish']
      pids.each { |pid| csv.add_row([pid, 'academic_commons', 'TRUE']) }
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

      if assets.blank? || assets.count.zero?
        puts Rainbow("WARN: #{agr_pid} does not have any assets.").yellow
      end

      assets.each do |asset|
        pid = asset['member'].gsub('info:fedora/', '')
        title = asset['title']
        assets_to_aggregators << [pid, 'asset', agr_pid, 'academic_commons', title]
      end
    end

    asset_csv = aggregator_csv.sub('hyacinth-import', 'asset-to-aggregators')

    # Create aggregator to asset csv.
    CSV.open(asset_csv, "w") do |csv|
      csv.add_row(headers)
      assets_to_aggregators.each { |row| csv.add_row(row) }
    end
  end
end
