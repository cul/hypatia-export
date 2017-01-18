require 'csv'
require 'hyacinth_export/uri_mapping'

module HyacinthExport
  class CSV
    include HyacinthExport::UriMapping

    attr_accessor :table, :prefix

    def initialize(filename, prefix: '')
      array_of_arrays = ::CSV.read(filename, encoding: 'ISO8859-1')
      headers = array_of_arrays.first
      array_of_rows = array_of_arrays.drop(1).map { |r| ::CSV::Row.new(headers, r) }
      self.table = ::CSV::Table.new(array_of_rows)
      self.prefix = prefix
    end

    def headers
      self.table.headers
    end

    def delete_columns(column_names, with_prefix: false)
     column_names.each do |n|
       n = "#{self.prefix}:#{n}" unless with_prefix
       self.table.delete(n)
     end
    end

    def add_column(name, default_content: nil)
      self.table.each do |row|
        row[name] = default_content
      end
    end

    def rename_column(old_name, new_name)
      self.table.each do |row|
        row[new_name] = row[old_name]
      end
      delete_columns([old_name], with_prefix: true)
      # delete old row
    end

    def merge_columns(from, to)
      from = "#{prefix}:#{from}"
      to = "#{prefix}:#{to}"
      self.table.each do |row|
        # throw an error is both columns have a value and the value is not the same
        if !row[from].blank? && !row[to].blank? && row[to] != row[from]
          raise "Cannot merge #{from} and #{to}. Please merge manually."
        end
        row[to] = row[from] || row[to]
      end

      # from column is deleted, to column is saved
      delete_columns([from], with_prefix: true)
    end

   def value_to_uri(value_column, uri_column_name, map)
     # update the values in the value column to uris
     self.table.each do |row|
       if row[value_column]
         value = row[value_column].downcase
         uri = map[value]
         if uri
           row[value_column] = uri
         else
           raise "could not find uri for #{value}"
         end
       end
     end
     # rename column to uri_column_name
     rename_column(value_column, uri_column_name)
     # array.first[i] = uri_column_name
     # array
   end

    def export_to_file
      filename = File.join(Rails.root, 'tmp', 'data', "#{self.prefix}-import-to-hyacinth.csv")

      ::CSV.open(filename, 'w', encoding: 'ISO8859-1') do |csv|
       self.table.to_a.each { |row| csv.add_row(row) }
      end
      filename
    end

    def normalize_doi(column_name)
      self.table.each do |row|
        doi = row[column_name]
        if m = /http\:\/\/dx.doi.org\/(.+)/.match(doi)
          row[column_name] = m[1]
        end
      end
    end

    def combine_name(first_name_column, last_name_column)
      self.table.each do |row|
        if (last_name = row[last_name_column]) && (first_name = row[first_name_column])
          row[last_name_column] = "#{last_name}, #{first_name}"
        end
      end
    end
  end
end
