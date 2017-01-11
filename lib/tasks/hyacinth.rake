require 'csv'
require 'hyacinth_export'

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
    HyacinthExport.export_values
  end
end
