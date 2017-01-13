require 'csv'
require 'hyacinth_export/uri_mapping'

module HyacinthExport
  class CSV
    include HyacinthExport::UriMapping

    attr_accessor :array

    def initialize(filename)
      self.array = ::CSV.read(filename)
    end

    def headers
      array.first
    end

    def delete_columns(column_names)
      indexes = column_names.map { |n| headers.find_index(n) }.compact.uniq.sort.reverse
      array.each do |row|
        indexes.each { |i| row.delete_at(i) }
      end
    end

    def export_to_file(filename)
      ::CSV.open(filename, 'w') do |csv|
       array.each { |row| csv.add_row(row) }
      end
    end
  end
end
