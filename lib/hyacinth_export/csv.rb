require 'csv'

module HyacinthExport
  class CSV
    attr_accessor :table, :prefix, :export_filepath, :import_filepath

    def initialize(export_filepath, import_filepath, prefix: '')
      self.prefix = prefix
      self.export_filepath = export_filepath
      self.import_filepath = import_filepath

      array_of_arrays = ::CSV.read(self.export_filepath, encoding: 'UTF-8')
      headers = array_of_arrays.first
      array_of_rows = array_of_arrays.drop(1).map { |r| ::CSV::Row.new(headers, r) }
      self.table = ::CSV::Table.new(array_of_rows)

      # Add project column and remove _hypatia_id
      add_column('_project.string_key', default_content: 'academic_commons')
      delete_columns(['_hypatia_id'], with_prefix: true)
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

    def add_column(*names, default_content: nil)
      names = [names] if names.is_a?(String)
      self.table.each do |row|
        names.each do |name|
          row[name] = default_content
        end
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

    def value_to_uri(value_column, uri_column_name, map, case_sensitive: false)
      # update the values in the value column to uris
      add_column(uri_column_name)
      self.table.each do |row|
        next if row[value_column].blank?
        value = row[value_column]
        value = value.downcase unless case_sensitive
        uri = map[value]
        if uri
          row[uri_column_name] = uri
        else
          raise "could not find matching value for #{value}"
        end
      end
    end

    def export_to_file
      ::CSV.open(self.import_filepath, 'w', encoding: 'UTF-8') do |csv|
        # Sorting header by alphabetical order. If begining of header is the same
        # headers are stored by number.
        sorted_headers = headers.sort do |a, b|
          regex = /^(.*)-(\d*):(.*)/
          a_match = regex.match(a)
          b_match = regex.match(b)
          if !a_match.nil? && !b_match.nil? && (a_match[1] == b_match[1])
            if a_match[2].to_i == b_match[2].to_i
              a_match[3] <=> b_match[3]
            else
              a_match[2].to_i <=> b_match[2].to_i
            end
          else
            a <=> b
          end
        end

        csv.add_row(sorted_headers)
        self.table.each do |row|
          csv.add_row(row.fields(*sorted_headers))
        end
      end
    end

    def normalize_doi(column_name)
      self.table.each do |row|
        doi = row[column_name]
        if m = /http\:\/\/dx\.doi\.org\/(.+)/.match(doi)
          row[column_name] = m[1]
        end
      end
    end

    def add_name_type(num:, type:)
       add_column("name-#{num}:name_term.name_type")
       self.table.each do |row|
         unless row["name-#{num}:name_term.value"].blank?
           row["name-#{num}:name_term.name_type"] = type
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

    # Maps subjects that don't have URIs and are valid ProQuest subjects to Fast
    # Subjects. One subject can map to 0+ fast topics and 0+ fast geographic topics.
    def map_subjects_to_fast
      proquest_fast_map = HashWithIndifferentAccess.new(YAML.load_file("#{Rails.root}/lib/hyacinth_export/proquest_fast_map.yml"))

      self.table.each do |row|
        new_topics, new_geographic_topics = [], []
        subject_headers = headers.select { |h| /subject_topic-(\d+):subject_topic_term.value/.match(h) }
        subject_headers.each do |sub_header|
          uri_column = sub_header.gsub('value', 'uri')
          unless headers.include?(uri_column)
            add_column(uri_column)
          end

          next if row[sub_header].blank? || !row[uri_column].blank?

          subject = row[sub_header]
          fast_mapping = proquest_fast_map[subject.downcase]
          unless fast_mapping
            puts "No fast mapping for \"#{subject}\""
            next
          end

          row[sub_header] = nil
          row[uri_column] = nil

          new_topics.concat(fast_mapping[:topic] || [])
          new_geographic_topics.concat(fast_mapping[:geographic] || [])
        end

        # Get all empty geographic headers and make new columns if necessary
        geographic_headers = headers.select { |h| /subject_geographic-(\d+):subject_geographic_term.value/.match(h) }
        empty = geographic_headers.select { |h| row[h].blank? and row[h.gsub('value', 'uri')].blank? }
        if new_geographic_topics.size > empty.size # make new rows
          num = new_geographic_topics.size - empty.size
          (1..num).each do |i|
            new_header = "subject_geographic-#{geographic_headers.size + i}:subject_geographic_term.value"
            new_uri_header = new_header.gsub('value', 'uri')
            add_column(new_header, new_uri_header)
            empty << new_header
          end
        end

        add_topics(row, new_geographic_topics, empty)

        # Get all empty subject_headers and make new columns if necessary.
        # Add in new topics
        empty = subject_headers.select { |h| row[h].blank? and row[h.gsub('value', 'uri')].blank? }
        if new_topics.size > empty.size # make new rows
          num = new_topics.size - empty.size
          (1..num).each do |i|
            new_header = "subject_topic-#{subject_header.size + i}:subject_topic_term.value"
            new_uri_header = new_header.gsub('value', 'uri')
            add_column(new_header, new_uri_header)
            empty << new_header
          end
        end

        add_topics(row, new_topics, empty)
      end
    end

    private

    # Adds topic label and topic uri in the empty columns given.
    def add_topics(row, new_topics, empty_columns)
      empty_columns.sort_by!{ |s| s[/\d+/].to_i }.reverse!

      new_topics.each do |topic|
        column = empty_columns.pop
        raise 'not enough empty columns' if column.nil?
        row[column] = topic[:label]
        row[column.gsub('value', 'uri')] = topic[:uri]
      end
    end
  end
end
