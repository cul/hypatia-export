require 'hyacinth_mapping/uri_mapping'

module HyacinthMapping::TemplateMapping
  module AcWp10
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      PREFIX = 'acWP10'
      MAP = {
        'abstract'                         => 'abstract-1:abstract_value',
        'IDidentifierDOI'                  => 'doi_identifier-1:doi_identifier_value',
        'genreGenre'                       => 'genre-1:genre_term.value',
        'iDIdentifierHandle'               => 'cnri_handle_identifier-1:cnri_handle_identifier_value',
        'langLanguageTermText'             => 'language-1:language_term.value',
        'nameTypeCorporate:namePart'       => 'name-1:name_term.value',
        'nameTypeCorporate:nameRoleTerm'   => 'name-1:name_role-1:name_role_term.value',
        'nameTypeCorporate:nameRoleTerm-1' => 'name-1:name_role-2:name_role_term.value',
        'originDateIssued'                 => 'date_issued-1:date_issued_start_value',
        'originPlaceText'                  => 'place_of_origin-1:place_of_origin_value',
        'originPublisher'                  => 'publisher-1:publisher_value',
        'relatedItemSeries:partNumber'     => 'series-1:series_number',
        'relatedItemSeries:tiInfoTitle'    => 'series-1:series_title',
        'tiInfoTitle'                      => 'title-1:title_sort_portion',
        'typeResc'                         => 'type_of_resource-1:type_of_resource_value',
        'noteField'                        => 'note-1:note_value',
        'relatedItemSeries:seriesID'       => 'series-1:series_is_columbia'

      }

      def from_acwp10(export_filepath, import_filepath)
        csv = HyacinthMapping::CSV.new(export_filepath, import_filepath, prefix: PREFIX)

        csv.delete_columns(%w{
          Attachment IDidentifierURI copyEmbargo:EmRsrcVsbl copyEmbargo:copyEmAccessLevel
          copyEmbargo:copyEmDateBegin copyEmbargo:copyEmDateEnd copyEmbargo:copyEmIssuedBy
          copyEmbargo:copyEmNote copyright:accCCStatements copyright:copyCopyStatement
          extAuthorRightsStatement locURL nameTypeConference:namePart nameTypeConference:nameRoleTerm
          noteRef physDsExtentFileSize physDsInternetMediaType recInfRecordOrigin tableOfContents
          subjectGeoCode
        })

        # Map personal names
        name_matches = csv.headers.map{ |h| /#{PREFIX}:(nameAffil-?(\d*)):namePartFamily/.match(h) }.compact
        name_matches.each do |name|
          csv.combine_name("#{PREFIX}:#{name[1]}:namePartGiven", "#{PREFIX}:#{name[1]}:namePartFamily")
          csv.merge_columns("#{name[1]}:affilAffiliation:affilAuIDUNI", "#{name[1]}:affilAuIDUNI")

          num = name[2].to_i + 2

          csv.rename_column("#{PREFIX}:#{name[1]}:affilAuIDUNI", "name-#{num}:name_term.uni")
          csv.rename_column(name.string, "name-#{num}:name_term.value")

          # Role uri
          role_column = "name-#{num}:name_role-1:name_role_term.value"
          csv.rename_column("#{PREFIX}:#{name[1]}:nameRoleTerm", role_column)
          csv.map_values_to_uri(role_column, HyacinthMapping::UriMapping::ROLES_MAP)

          csv.add_name_type(num: num, type: 'personal')

          # Delete extra name columns no longer needed
          to_delete = [
            'affilDept', 'affilDept-1', 'affilDept-2', 'affilDept-3', 'namePartGiven', 'affilDept', 'namePartDate',
            'affilAffiliation:affilAuIDLocal', 'affilAffiliation:affilEmail', 'affilAffiliation:originCountry',
            'affilAffiliation:affilOrganization', 'affilAffiliation:affilDept', 'affilAffiliation:affilDeptOther',
            'affilAffiliation:affilDeptOther-1', 'affilAffiliation:affilAuIDNAF', 'affilAffiliation:affilDeptOther-2'
          ].map { |a| "#{name[1]}:#{a}" }
          csv.delete_columns(to_delete)
        end

        # Merge note columns.
        csv.merge_columns('noteField-1', 'noteField')

        num_sub_topic = csv.headers.select { |h| /^#{PREFIX}:subjectTopic-?(\d*)$/.match(h) }.count
        csv.headers.each do |header|
          no_prefix_header = header.gsub("#{PREFIX}:", '')

          if m = /^subjectTopicKeyword-?(\d*)$/.match(no_prefix_header)
           csv.rename_column(header, "subject_topic-#{m[1].to_i + num_sub_topic + 1}:subject_topic_term.value")
          elsif m = /^subjectTopic-?(\d*)$/.match(no_prefix_header)
           csv.rename_column(header, "subject_topic-#{m[1].to_i + 1}:subject_topic_term.value")
          elsif MAP[no_prefix_header] # mapping one-to-one fields
           csv.rename_column(header, MAP[no_prefix_header])
          end
        end

        # Map role terms from values to uris
        csv.map_values_to_uri('genre-1:genre_term.value', HyacinthMapping::UriMapping::GENRE_MAP)
        csv.map_values_to_uri('language-1:language_term.value', HyacinthMapping::UriMapping::LANGUAGE_MAP)

        # Add type for first (corporate) name.
        csv.add_name_type(num: 1, type: 'corporate')

        # Add role uri for corporate name.
        csv.map_values_to_uri("name-1:name_role-1:name_role_term.value", HyacinthMapping::UriMapping::ROLES_MAP)
        csv.map_values_to_uri("name-1:name_role-2:name_role_term.value", HyacinthMapping::UriMapping::ROLES_MAP)

        # Map proquest subjects to fast subjects
        csv.map_subjects_to_fast

        csv.export_to_file
      end
    end
  end
end
