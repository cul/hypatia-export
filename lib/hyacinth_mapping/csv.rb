require 'csv'

module HyacinthMapping
  class CSV
    attr_accessor :table, :prefix, :export_filepath, :import_filepath

    def initialize(export_filepath, import_filepath, prefix: '')
      self.prefix = prefix
      self.export_filepath = export_filepath
      self.import_filepath = import_filepath

      array_of_arrays = ::CSV.read(self.export_filepath, encoding: 'UTF-8')
      headers = array_of_arrays.first

      coder = HTMLEntities.new  # used to convert encoded characters.

      array_of_rows = array_of_arrays.drop(1).map do |r|
        r = r.map { |cell| coder.decode(cell) } # remove encoded characters
        ::CSV::Row.new(headers, r)
      end
      self.table = ::CSV::Table.new(array_of_rows)

      # Add project column and rename _hypatia_id
      add_column('_project.string_key', default_content: 'academic_commons')
      add_column('_digital_object_type.string_key', default_content: 'item')
      rename_column('_hypatia_id', 'hypatia_identifier-1:hypatia_identifier_value')
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

    # Merges columns if they have the same data, otherwise throws an error.
    def merge_columns(from, to)
      from = "#{prefix}:#{from}"
      to = "#{prefix}:#{to}"
      self.table.each do |row|
        # throw an error is both columns have a value and the value is not the same
        if !row[from].blank? && !row[to].blank? && row[to].strip != row[from].strip
          raise "Cannot merge #{from} and #{to} for the values #{row[from]} - #{row[to]}. Please merge manually."
        end
        row[to] = row[from] if row[to].blank?
      end

      # from column is deleted, to column is saved
      delete_columns([from], with_prefix: true)
    end

    # Joins columns. Keeps first column deletes rest of columns.
    def append_columns(*columns, seperator: ' ')
      self.table.each do |row|
        row[columns.first] = columns.map { |c| row[c] }.delete_if(&:blank?).join(seperator)
      end
      delete_columns(columns.drop(1), with_prefix: true)
    end

    # Returns headers of empty columns
    def empty_columns
      h = headers.clone
      table.each do |row|
        h.reject! { |header| !row[header].blank? }
      end
      h
    end

    def map_values_to_uri(value_column, map)
      uri_column = value_column.gsub('value', 'uri')
      authority_column = value_column.gsub('value', 'authority')
      add_column(uri_column, authority_column)

      self.table.each do |row|
        next if row[value_column].blank?
        value = row[value_column]
        value = value.downcase
        uri = map[value]
        if uri
          row[uri_column] = uri
          row[authority_column] = authority_for(uri)
        else
          puts "WARN: could not find matching uri for #{value}"
        end
      end
    end

    def map_values(value_column, mapped_column, map, case_sensitive: false)
      # update the values in the value column to uris
      add_column(mapped_column)
      self.table.each do |row|
        next if row[value_column].blank?
        value = row[value_column]
        value = value.downcase unless case_sensitive
        new_value = map[value]
        if new_value
          row[mapped_column] = new_value
        else
          puts "WARN: could not find matching value for #{value}"
        end
      end
    end

    def export_to_file
      ::CSV.open(self.import_filepath, 'w', encoding: 'UTF-8') do |csv|
        # Sorting header by alphabetical order. If begining of header is the same
        # headers are stored by number.
        sorted_headers = headers.sort do |a, b|
          regex = /^(\w+)-(\d+):(.*)$/
          a_match = regex.match(a)
          b_match = regex.match(b)
          if a_match && b_match && (a_match[1] == b_match[1])
            if a_match[2] == b_match[2]
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
        last_name, first_name = row[last_name_column], row[first_name_column]
        unless last_name.blank? && first_name.blank?
          row[last_name_column] = [last_name, first_name].join(', ')
        end
      end
    end

    # Maps subjects that don't have URIs and are valid ProQuest subjects to Fast
    # Subjects. One subject can map to 0+ fast topics and 0+ fast geographic topics.
    def map_subjects_to_fast
      proquest_fast_map = HashWithIndifferentAccess.new(YAML.load_file("#{Rails.root}/lib/hyacinth_mapping/subject_to_fast_map.yml"))

      self.table.each do |row|
        topics, geographic_topics = [], []

        # Extract and map all topic subjects
        subject_headers = headers.select { |h| /^subject_topic-(\d+):subject_topic_term.value$/.match(h) }
        subject_headers.each do |sub_header|
          uri_column = sub_header.gsub('value', 'uri')
          authority_column = sub_header.gsub('value', 'authority')

          add_column(uri_column)       unless headers.include?(uri_column)
          add_column(authority_column) unless headers.include?(authority_column)

          subject = row[sub_header]
          subject = subject.strip unless subject.nil?
          uri = row[uri_column]

          if subject.blank? && row[uri_column].blank?
            next
          elsif !row[uri_column].blank?
            topics.append({ label: subject, uri: uri })
          elsif fast_mapping = proquest_fast_map[subject.downcase]
            topics.concat(fast_mapping[:topic] || [])
            geographic_topics.concat(fast_mapping[:geographic] || [])
          else
            topics.append({ label: subject, uri: uri })
            puts "WARN: No fast mapping for \"#{subject}\""
          end

          row[sub_header] = nil
          row[uri_column] = nil
          row[authority_column] = nil
        end

        # Extract all fast geographic subjects
        geographic_headers = headers.select { |h| /^subject_geographic-(\d+):subject_geographic_term.value$/.match(h) }
        geographic_headers.each do |geo_header|
          uri_column = geo_header.gsub('value', 'uri')
          authority_column = geo_header.gsub('value', 'authority')

          add_column(uri_column)       unless headers.include?(uri_column)
          add_column(authority_column) unless headers.include?(authority_column)

          subject = row[geo_header]
          uri = row[uri_column]

          if subject.blank? && uri.blank?
            next
          elsif uri.blank?
            raise "FAST geographic subject with no uri: #{subject}"
          else
            geographic_topics.append({ label: subject, uri: uri })
          end

          row[geo_header] = nil
          row[uri_column] = nil
          row[authority_column] = nil
        end

        # Removing duplicates
        topics.uniq! { |t| t[:uri] || t[:label] }
        geographic_topics.uniq! { |t| t[:uri] || t[:label] }

        # Get all empty geographic headers and make new columns if necessary
        geographic_headers = headers.select { |h| /^subject_geographic-(\d+):subject_geographic_term.value$/.match(h) }
        empty = geographic_headers.select { |h| row[h].blank? and row[h.gsub('value', 'uri')].blank? }
        if geographic_topics.size > empty.size # make new rows
          num = geographic_topics.size - empty.size
          (1..num).each do |i|
            new_header = "subject_geographic-#{geographic_headers.size + i}:subject_geographic_term.value"
            new_uri_header = new_header.gsub('value', 'uri')
            new_authority_header = new_header.gsub('value', 'authority')
            add_column(new_header, new_uri_header, new_authority_header)
            empty << new_header
          end
        end

        add_topics(row, geographic_topics, empty)

        # Get all empty subject_headers and make new columns if necessary.
        # Add in new topics
        empty = subject_headers.select { |h| row[h].blank? and row[h.gsub('value', 'uri')].blank? }
        if topics.size > empty.size # make new rows
          num = topics.size - empty.size
          (1..num).each do |i|
            new_header = "subject_topic-#{subject_headers.size + i}:subject_topic_term.value"
            new_uri_header = new_header.gsub('value', 'uri')
            add_column(new_header, new_uri_header)
            empty << new_header
          end
        end

        add_topics(row, topics, empty)
      end

      # Remove empty subject_headers columns
      subject_headers = headers.select { |h| /subject_topic-(\d+):subject_topic_term.value/.match(h) }
      subject_headers.each do |s|
        uri = s.gsub('value', 'uri')
        authority = s.gsub('value', 'authority')
        if column_empty?(s) && column_empty?(uri)
          delete_columns([s, uri, authority], with_prefix: true)
        end
      end
    end

    private

    def authority_for(uri)
      authority_map = {
        'marcrelator' => 'http://id.loc.gov/vocabulary/relators/',
        'iso639-2b'	  => 'http://id.loc.gov/vocabulary/iso639-2/',
        'fast'        => 'http://id.worldcat.org/fast/',
        'aat'	        => 'http://vocab.getty.edu/aat/',
        'gmgpc'	      => 'http://id.loc.gov/vocabulary/graphicMaterials/',
        'lcgft'	      => 'http://id.loc.gov/authorities/genreForms/',
        # 'tbd'            => 'http://purl.org/coar/resource_type/',
      }

      name, beg_uri = authority_map.find { |_, value| /^#{Regexp.escape(value)}.*$/ =~ uri }
      puts "WARN: Could not find authority for #{uri}" if name.nil?
      name
    end

    def column_empty?(name)
      self.table.each do |row|
        return false unless row[name].blank?
      end
      true
    end

    # Adds topic label and topic uri in the empty columns given.
    def add_topics(row, new_topics, empty_columns)
      empty_columns.sort_by!{ |s| s[/\d+/].to_i }.reverse!

      new_topics.each do |topic|
        column = empty_columns.pop
        raise 'not enough empty columns' if column.nil?
        row[column] = topic[:label]
        row[column.gsub('value', 'uri')] = topic[:uri]
        row[column.gsub('value', 'authority')] = 'fast' unless topic[:uri].blank?
      end
    end
  end
end
