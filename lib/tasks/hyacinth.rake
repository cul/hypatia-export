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
end
