require 'hyacinth_mapping/uri_mapping'

module HyacinthMapping::TemplateMapping
  module AcTypeBook
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      PREFIX = 'acTypeBook'
      MAP = {
        'abstract'             => 'abstract-1:abstract_value',
        'genreGenre'           => 'genre-1:genre_term.value',
        'iDIdentifierHandle'   => 'cnri_handle_identifier-1:cnri_handle_identifier_value',
        'iDIdentifierISBN'     => 'isbn-1:isbn_value',
        'langLanguageTermText' => 'language-1:language_term.value',
        'noteField'            => 'note-1:note_value',
        'originDateIssued'                   => 'date_issued-1:date_issued_start_value',
        'originPlace:originCity'             => 'place_of_origin-1:place_of_origin_value',
        'originPlaceText'                    => 'place_of_origin-1:place_of_origin_value',
        'originPublisher'                    => 'publisher-1:publisher_value',
        'relatedItemSeries:iDIdentifierISSN' => 'series-1:series_issn',
        'relatedItemSeries:partNumber'       => 'series-1:series_number',
        'relatedItemSeries:tiInfoTitle'      => 'series-1:series_title',
        'relatedItemSeries:seriesID'         => 'series-1:series_is_columbia',
        'tiInfoTitle'                        => 'title-1:title_sort_portion',
        'typeResc'                           => 'type_of_resource-1:type_of_resource_value',
      }

      def from_actypebook(export_filepath, import_filepath)
        csv = HyacinthMapping::CSV.new(export_filepath, import_filepath, prefix: PREFIX)

        csv.delete_columns(%w{
          Attachments classLC copyEmbargo:EmRsrcVsbl tiInfoSubTitle originEdition
          copyEmbargo:copyEmAccessLevel copyEmbargo:copyEmDateBegin relatedItemSeries:iDIdentifierISSN-1
          copyEmbargo:copyEmDateEnd copyEmbargo:copyEmIssuedBy nameTypeConference:nameRoleTerm
          copyEmbargo:copyEmNote copyright:accCCStatements copyEmbargo:EmPeerReview
          copyright:copyCopyNotice copyright:copyCopyStatement nameTypeConference:namePart
         	copyright:copyCopyStatus copyright:copyCountry nameTypeConference:namePart
          copyright:copyPubStatus copyright:copyRightsContact copyright:copyRightsName
          copyright:copyRightsNote copyright:copyYear extAuthorRightsStatement
          iDIdentifierLocal identifierDOI tableOfContents physDsInternetMediaType
          physDsExtentFileSize	physDsExtentPages recInfRecordOrigin physDsNote
          originState physDsDigitalOrigin originPlace:originCountry
          originPlace:originState noteRef locURL relatedItemSeries:partNumber-1
        })

        csv.append_columns('acTypeBook:noteField', "acTypeBook:noteField-1")

        # Map corporate names
        corporate_matches = csv.headers.map { |h| /#{PREFIX}:(nameTypeCorporate-?(\d*)):namePart/.match(h) }.compact
        corporate_matches.each do |name|
          num = name[2].to_i + 1

          role_match = csv.headers.map { |h| /#{PREFIX}:#{name[1]}:nameRoleTerm-?(\d*)/.match(h) }.compact
          role_match.each do |role|
            new_column = "name-#{num}:name_role-#{role[1].to_i + 1}:name_role_term.value"
            csv.rename_column(role.string, "name-#{num}:name_role-#{role[1].to_i + 1}:name_role_term.value")
            csv.map_values_to_uri(new_column, HyacinthMapping::UriMapping::ROLES_MAP)
          end

          csv.rename_column(name.string, "name-#{num}:name_term.value")
          csv.add_name_type(num: num, type: 'corporate')

          csv.delete_columns(["#{name[1]}:displayForm"])
        end

        # Map personal names
        name_matches = csv.headers.map{ |h| /#{PREFIX}:(nameAffil-?(\d*)):namePartFamily/.match(h) }.compact
        name_matches.each do |name|
          csv.combine_name("#{PREFIX}:#{name[1]}:namePartGiven", "#{PREFIX}:#{name[1]}:namePartFamily")
          csv.merge_columns("#{name[1]}:affilAffiliation:affilAuIDUNI", "#{name[1]}:affilAuIDUNI")

          num = name[2].to_i + corporate_matches.count + 1

          csv.rename_column("#{PREFIX}:#{name[1]}:affilAuIDUNI", "name-#{num}:name_term.uni")
          csv.rename_column(name.string, "name-#{num}:name_term.value")

          # Role uri
          role_column = "name-#{num}:name_role-1:name_role_term.value"
          csv.rename_column("#{PREFIX}:#{name[1]}:nameRoleTerm", role_column)
          csv.map_values_to_uri(role_column, HyacinthMapping::UriMapping::ROLES_MAP)

          csv.add_name_type(num: num, type: 'personal')

          # Delete extra name columns no longer needed
          # Delete role columns that contain duplicate data in this mapping
          to_delete = [
            'affilDept', 'affilDept-1', 'affilDept-2', 'affilDept-3', 'namePartGiven', 'affilDept', 'namePartDate',
            'affilAffiliation:affilAuIDLocal', 'affilAffiliation:affilEmail', 'affilAffiliation:originCountry',
            'affilAffiliation:affilOrganization', 'affilAffiliation:affilOrganization-1', 'affilAffiliation:affilDept',
            'affilAffiliation:affilDeptOther',
            'affilAffiliation:affilDeptOther-1', 'affilAffiliation:affilAuIDNAF', 'affilAffiliation:affilDeptOther-2',
            'affiliation', 'nameID', 'affilAffiliation:affilDept-1', 'nameRoleTerm-1'
          ].map { |a| "#{name[1]}:#{a}" }
          csv.delete_columns(to_delete)
        end

        num_sub_topic = csv.headers.select { |h| /^#{PREFIX}:subjectTopic-?(\d*)$/.match(h) }.count
        subject_count = 1
        csv.headers.each do |header|
          no_prefix_header = header.gsub("#{PREFIX}:", '')

          if m = /^(subjectTopicKeyword|subjectTopic|subjectGeoCode)-?\d*$/.match(no_prefix_header)
            csv.rename_column(header, "subject_topic-#{subject_count}:subject_topic_term.value")
            subject_count += 1
          elsif MAP[no_prefix_header] # mapping one-to-one fields
            csv.rename_column(header, MAP[no_prefix_header])
          end
        end

        # Map role terms from values to uris
        csv.map_values_to_uri('genre-1:genre_term.value', HyacinthMapping::UriMapping::GENRE_MAP)
        csv.map_values_to_uri('language-1:language_term.value', HyacinthMapping::UriMapping::LANGUAGE_MAP)

        # Map proquest subjects to fast subjects
        csv.map_subjects_to_fast

        csv.export_to_file
      end
    end
  end
end
