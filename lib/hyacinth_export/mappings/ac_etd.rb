module HyacinthExport::Mappings
  module AcEtd
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      DEGREE_TO_NUM = {
        'Senior Thesis' => 0, 'Senior thesis' => 0, 'B.A.' => 0, 'M.F.A.' => 1,
        'M.P.H.' => 1, 'M.A.' => 1, 'M.Div.' => 1, 'M.S.' => 1, 'Ph.D.' => 2,
        'Ed.D.' => 2, 'Dr.P.H.' => 2, 'J.S.D.' => 2, 'D.M.A.' => 2,
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
        'embargo:embargoRelease'   => 'embargo_release_date-1:embargo_release_date_value',
      }

      # Map CSV headers from acETD Hypatia csv to Hyacinth compatible csv
      def from_acetd(export_filepath, import_filepath)
        csv = HyacinthExport::CSV.new(export_filepath, import_filepath, prefix: PREFIX)

        csv.delete_columns(%w{
          _hypatia_id copyright:copyrightNotice copyright:creativeCommonsLicense tableOfContents
          RIOXX:Funder RIOXX:Grant attachment embargo:embargoLength embargo:embargoNote
          embargo:embargoStart
        })

        # Merge note columns.
        csv.merge_columns('note-1', 'note')

        # Map personal names
        name_matches = csv.headers.map { |h| /#{PREFIX}:(namePersonal-?(\d*)):namePartFamily/.match(h) }.compact
        name_matches.each do |name|
          csv.combine_name("#{PREFIX}:#{name[1]}:namePartGiven", "#{PREFIX}:#{name[1]}:namePartFamily")

          num = name[2].to_i + 1

          # Rename all role row columns
          role_match = csv.headers.map { |h| /#{PREFIX}:#{name[1]}:role-?(\d*)/.match(h) }.compact
          role_match.each do |role|
            new_column = "name-#{num}:name_role-#{role[1].to_i + 1}:name_role_term.value"
            csv.rename_column(role.string, "name-#{num}:name_role-#{role[1].to_i + 1}:name_role_term.value")
            csv.value_to_uri(new_column, new_column.gsub('.value', '.uri'), HyacinthExport::UriMapping::ROLES_MAP)
          end

          # Rename rest of columns
          csv.rename_column("#{PREFIX}:#{name[1]}:nameID", "name-#{num}:name_uni.value")
          csv.rename_column(name.string, "name-#{num}:name_term.value")

          csv.add_name_type(num: num, type: 'personal')

          delete = ['namePartGiven', 'affiliation', 'affiliation-1', 'affiliation-2', 'affiliation-3',
            'affiliationList', 'affiliation-4'].map{ |h| "#{name[1]}:#{h}"}
          csv.delete_columns(delete)
        end

        # Map corporate names
        corporate_matches = csv.headers.map { |h| /#{PREFIX}:(nameCorporate-?(\d*)):namePart/.match(h) }.compact
        corporate_matches.each do |name|
          num = name_matches.count + name[2].to_i + 1

          role_match = csv.headers.map { |h| /#{PREFIX}:#{name[1]}:role-?(\d*)/.match(h) }.compact
          role_match.each do |role|
            new_column = "name-#{num}:name_role-#{role[1].to_i + 1}:name_role_term.value"
            csv.rename_column(role.string, "name-#{num}:name_role-#{role[1].to_i + 1}:name_role_term.value")
            csv.value_to_uri(new_column, new_column.gsub('.value', '.uri'), HyacinthExport::UriMapping::ROLES_MAP)
          end

          csv.rename_column(name.string, "name-#{num}:name_term.value")
          csv.add_name_type(num: num, type: 'corporate')
        end

        # Mapping rest of columns
        num_fast = csv.headers.select{ |h| /#{PREFIX}:FAST-?(\d+)?:FASTURI/.match(h) }.count
        csv.headers.each do |header|
          no_prefix_header = header.gsub("#{PREFIX}:", '')

          if m = /^FAST-?(\d*):FASTURI$/.match(no_prefix_header)
            csv.rename_column(header, "subject_topic-#{m[1].to_i+1}:subject_topic_term.uri")
          elsif m = /^FAST-?(\d*):FASTSubject$/.match(no_prefix_header)
            csv.rename_column(header, "subject_topic-#{m[1].to_i+1}:subject_topic_term.value")
          elsif m = /^subject-?(\d*)$/.match(no_prefix_header)
            num = m[1].to_i + 1 + num_fast
            csv.rename_column(header, "subject_topic-#{num}:subject_topic_term.value")
          elsif m = /^FASTGeo-?(\d*):GeoURI$/.match(no_prefix_header)
            csv.rename_column(header, "subject_geographic-#{m[1].to_i + 1}:subject_geographic_term.uri")
          elsif m = /^FASTGeo-?(\d*):Geo$/.match(no_prefix_header)
            csv.rename_column(header, "subject_geographic-#{m[1].to_i + 1}:subject_geographic_term.value")
          elsif MAP[no_prefix_header] # mapping one-to-one fields
            csv.rename_column(header, MAP[no_prefix_header])
          end
        end

        # Degree and URI Mappings
        csv.value_to_uri('degree-1:degree_name', 'degree-1:degree_level', DEGREE_TO_NUM, case_sensitive: true)
        csv.value_to_uri('genre-1:genre_term.value', 'genre-1:genre_term.uri', HyacinthExport::UriMapping::GENRE_MAP)
        csv.value_to_uri('language-1:language_term.value', 'language-1:language_term.uri', HyacinthExport::UriMapping::LANGUAGE_MAP)

        csv.map_subjects_to_fast

        csv.export_to_file
      end
    end
  end
end
