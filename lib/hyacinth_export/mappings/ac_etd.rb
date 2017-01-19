module HyacinthExport::Mappings
  module AcEtd
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      DEGREE_TO_NUM = {
        'Senior Thesis' => 0, 'B.A.' => 0, 'M.F.A.' => 1, 'M.P.H.' => 1, 'M.A.' => 1,
        'M.Div.' => 1, 'M.S' => 1, 'Ph.D.' => 2, 'Ed.D.' => 2, 'Dr.P.H.' => 2,
        'J.S.D.' => 2, 'D.M.A.' => 2,
      }
      PREFIX = 'acETD'
      MAP = {
        'abstract'                 => 'abstract-1:abstract_value',
        'genre'                    => 'genre-1:genre_term.value',
        'identifierHDL'            => 'cnri_handle_identifier-1:cnri_handle_identifier_value',
        'identifierISBN'           => 'isbn-1:isbn_value',
        'ezid'                     => 'doi_identifier-1:doi_identifier_value',
        'language'                 => 'language-1:language_term.value',
        'note'                     => 'note-1:note_value',
        'originInfoDateIssued'     => 'date_issued-1:date_issued_start_value',
        'originInfoPlace'          => 'place_of_origin-1:place_of_origin_value',
        'originInfoPublisher'      => 'publisher-1:publisher_value',
        'title'                    => 'title-1:title_sort_portion',
        'typeOfResource'           => 'type_of_resource-1:type_of_resource_value',
        'degreeInfo:degreeGrantor' => 'degree-1:degree_grantor',
        'degreeInfo:degreeName'    => 'degree-1:degree_name',
        'nameCorporate:namePart'   => 'name-1:name_term.value',
        'nameCorporate:role'       => 'name-1:name_role-1:name_role_term.value'
      }

      # Map CSV headers from acETD Hypatia csv to Hyacinth compatible csv
      def from_acetd(filename)
        csv = HyacinthExport::CSV.new(filename, prefix: PREFIX)

        csv.delete_columns(%w{
          copyright:copyrightNotice copyright:creativeCommonsLicense tableOfContents
          RIOXX:Funder RIOXX:Grant attachment
        })

        # Combine proquest and FAST subjects and map them to new column names
        subject_headers = csv.headers.select{ |h| /#{PREFIX}:FAST-?(\d+)?:FASTURI|#{PREFIX}:subject-?(\d*)/.match(h) }
        (1..subject_headers.count).each do |num|
          csv.add_column("subject_topic-#{num}:subject_topic_term.value")
          csv.add_column("subject_topic-#{num}:subject_topic_term.uri")
        end

        to_delete = []
        csv.table.each do |row|
          subjects = []
          subject_headers.each do |s|
            if m = /#{PREFIX}:FAST-?(\d+)?:FASTURI/.match(s)
              subjects << { value: row[s.gsub('FASTURI', 'FASTSubject')], uri: row[s]}
              to_delete.concat([s, s.gsub('FASTURI', 'FASTSubject')])
            else
              subjects << { value: row[s], uri: nil }
              to_delete.append(s)
            end
          end
          subjects.delete_if { |a| a[:value].blank? && a[:uri].blank? }
          subjects.each_with_index do |hash, index|
            row["subject_topic-#{index+1}:subject_topic_term.value"] = hash[:value]
            row["subject_topic-#{index+1}:subject_topic_term.uri"] = hash[:uri]
          end
        end

        csv.delete_columns(to_delete, with_prefix: true) # add value fields of Fast to be deleted also

        # join first and last name
        name_prefixes = csv.headers.map { |h| /#{PREFIX}:(namePersonal(-\d+)?):namePartFamily/.match(h) }.compact.map { |m| m[1] }
        name_prefixes.each do |name|
          csv.combine_name("#{PREFIX}:#{name}:namePartGiven", "#{PREFIX}:#{name}:namePartFamily")

          delete = ['namePartGiven', 'affiliation', 'affiliation-1', 'affiliation-2', 'affiliation-3', 'affiliationList'].map{ |h| "#{name}:#{h}"}
          csv.delete_columns(delete)
        end

        # Mapping rest of columns.
        csv.headers.each do |header|
          no_prefix_header = header.gsub("#{PREFIX}:", '')

          if m = /#{PREFIX}:namePersonal-?(\d+)?:(\w+)/.match(header)
            name_field_map = {
              'namePartFamily' => 'name_term.value',
              'role'           => 'name_role-1:name_role_term.value',
              'nameID'         => 'name_uni.value'
            }
            if field = name_field_map[m[2]]
              num = m[1].to_i + 2 # increment by 2
              csv.rename_column(header, "name-#{num}:#{field}")
            end
          elsif MAP[no_prefix_header] # mapping one-to-one fields
            csv.rename_column(header, MAP[no_prefix_header])
          end
        end

        # Degree and URI Mappings
        csv.value_to_uri('degree-1:degree_name', 'degree-1:degree_level', DEGREE_TO_NUM, case_sensitive: true)
        csv.value_to_uri('genre-1:genre_term.value', 'genre-1:genre_term.uri', HyacinthExport::UriMapping::GENRE_MAP)
        csv.value_to_uri('language-1:language_term.value', 'language-1:language_term.uri', HyacinthExport::UriMapping::LANGUAGE_MAP)

       # Add person type column and person role uri mapping
       csv.headers.map{ |h| /name-(\d+)/.match(h) }.compact.map{ |m| m[1] }.each do |num|
         csv.value_to_uri("name-#{num}:name_role-1:name_role_term.value", "name-#{num}:name_role-1:name_role_term.uri", HyacinthExport::UriMapping::ROLES_MAP)

         type = (num.to_i == 1) ? 'corporate' : 'personal'
         csv.add_column("name-#{num}:name_term.name_type")
         csv.table.each do |row|
           unless row["name-#{num}:name_term.value"].blank?
             row["name-#{num}:name_term.name_type"] = type
           end
         end
       end

        csv.export_to_file
      end
    end
  end
end
