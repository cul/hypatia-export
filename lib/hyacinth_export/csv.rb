require 'csv'
require 'hyacinth_export/uri_mapping'

module HyacinthExport
  class CSV
    include HyacinthExport::UriMapping

    attr_accessor :array, :prefix

    def initialize(filename, prefix: '')
      self.array = ::CSV.read(filename)
      self.prefix = prefix
    end

    def headers
      array.first
    end

    def delete_columns(column_names, with_prefix: false)
      indexes = column_names.map do |n|
        n = "#{self.prefix}:#{n}" unless with_prefix
        headers.find_index(n)
      end.compact.uniq.sort.reverse
      array.each do |row|
        indexes.each { |i| row.delete_at(i) }
      end
    end

    def merge_columns(from, to)
      from = "#{prefix}:#{from}"
      to = "#{prefix}:#{to}"
      from_index = headers.find_index(from)
      to_index = headers.find_index(to)
      return if from_index.nil? || to_index.nil?
      (1...array.length-1).each do |i|
        row = array[i]
        # throw an error is both columns have a value and the value is not the same
        if !row[from_index].blank? && !row[to_index].blank?
          raise "Cannot merge #{from} and #{to} on row: #{i}. Please merge manually."
        end
        row[to_index] = row[from_index] || row[to_index]
      end

      # from column is deleted, to column is saved
      delete_columns([from.gsub("#{prefix}:", '')])
    end

    def export_to_file
      filename = File.join(Rails.root, 'tmp', 'data', "#{self.prefix}-export-to-hypatia.csv")
      ::CSV.open(filename, 'w') do |csv|
       array.each { |row| csv.add_row(row) }
      end
      filename
    end
  end
end
