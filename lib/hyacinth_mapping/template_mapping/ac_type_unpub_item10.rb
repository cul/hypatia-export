require 'hyacinth_mapping/uri_mapping'
require 'hyacinth_mapping/csv'

module HyacinthMapping::TemplateMapping
  module AcTypeUnpubItem10
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      PREFIX = 'acTypeUnpubItem10'
      MAP = {
        'abstract'             => 'abstract-1:abstract_value',
        'genreGenre'           => 'genre-1:genre_term.value',
        'iDIdentifierHandle'   => 'cnri_handle_identifier-1:cnri_handle_identifier_value',
        'langLanguageTermText' => 'language-1:language_term.value',
        'noteField'            => 'note-1:note_value',
        'originDateIssued'     => 'date_issued-1:date_issued_start_value',
        'tiInfoTitle'          => 'title-1:title_sort_portion',
        'typeResc'             => 'type_of_resource-1:type_of_resource_value',
        'IDidentifierDOI' => 'parent_publication-1:parent_publication_doi'
      }

      def from_actypeunpubitem10(export_filepath, import_filepath)
        csv = HyacinthMapping::CSV.new(export_filepath, import_filepath, prefix: PREFIX)

        csv.delete_columns(%w{
          Attachment IDidentifierURI copyEmbargo:EmPeerReview copyEmbargo:EmRsrcVsbl
          copyEmbargo:copyEmAccessLevel copyEmbargo:copyEmDateBegin copyEmbargo:copyEmDateEnd
          copyEmbargo:copyEmIssuedBy copyEmbargo:copyEmNote copyright:accCCStatements
          copyright:copyCopyStatement copyright:copyCopyStatus copyright:copyCountry
          copyright:copyPubStatus copyright:copyRightsContact copyright:copyRightsName
          copyright:copyRightsNote copyright:copyYear extAuthorRightsStatement
          iDIdentifierLocal nameTypeConference:namePart nameTypeConference:nameRoleTerm
          physDsExtentFileSize  physDsExtentPages physDsInternetMediaType recInfRecordOrigin
          relatedItemReferences:IDidentifierDOI relatedItemReferences:locURL
          relatedItemReferences:noteField relatedItemReferences:tiInfoTitle
          subjectGeoCode tableOfContents tiInfoSubTitle locURL
        })

        # Append note fields
        csv.append_columns("#{PREFIX}:noteField", "#{PREFIX}:noteField-1", "#{PREFIX}:noteField-2", "#{PREFIX}:noteRef")

        # Map corporate names
        corporate_matches = csv.headers.map { |h| /#{PREFIX}:(nameTypeCorporate-?(\d*)):namePart/.match(h) }.compact
        corporate_matches.each do |name|
          num = name[2].to_i + 1

          role_match = csv.headers.map { |h| /#{PREFIX}:#{name[1]}:nameRoleTerm-?(\d*)/.match(h) }.compact
          role_match.each do |role|
            new_column = "name-#{num}:name_role-#{role[1].to_i + 1}:name_role_term.value"
            csv.rename_column(role.string, "name-#{num}:name_role-#{role[1].to_i + 1}:name_role_term.value")
            csv.value_to_uri(new_column, new_column.gsub('.value', '.uri'), HyacinthMapping::UriMapping::ROLES_MAP)
          end

          csv.rename_column(name.string, "name-#{num}:name_term.value")
          csv.add_name_type(num: num, type: 'corporate')
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
          csv.value_to_uri(role_column, role_column.gsub('.value', '.uri'), HyacinthMapping::UriMapping::ROLES_MAP)

          csv.add_name_type(num: num, type: 'personal')

          # Delete extra name columns no longer needed
          to_delete = [
            'affilDept', 'affilDept-1', 'affilDept-2', 'affilDept-3', 'namePartGiven', 'affilDept', 'namePartDate',
            'affilAffiliation:affilAuIDLocal', 'affilAffiliation:affilEmail', 'affilAffiliation:originCountry',
            'affilAffiliation:affilOrganization', 'affilAffiliation:affilDept', 'affilAffiliation:affilDeptOther',
            'affilAffiliation:affilDeptOther-1', 'affilAffiliation:affilAuIDNAF', 'affilAffiliation:affilDeptOther-2',
            'affiliation', 'nameID', 'affilAffiliation:affilDept-1'
          ].map { |a| "#{name[1]}:#{a}" }
          csv.delete_columns(to_delete)
        end

        num_sub_topic = csv.headers.select { |h| /^#{PREFIX}:subjectTopic-?(\d*)$/.match(h) }.count
        csv.headers.each do |header|
          no_prefix_header = header.gsub("#{PREFIX}:", '')

          if m = /^subjectTopicCU-?(\d*)$/.match(no_prefix_header)
            csv.rename_column(header, "subject_topic-#{m[1].to_i + num_sub_topic + 1}:subject_topic_term.value")
          elsif m = /^subjectTopic-?(\d*)$/.match(no_prefix_header)
            csv.rename_column(header, "subject_topic-#{m[1].to_i + 1}:subject_topic_term.value")
          elsif MAP[no_prefix_header] # mapping one-to-one fields
            csv.rename_column(header, MAP[no_prefix_header])
          end
        end

        # Map role terms from values to uris
        csv.value_to_uri('genre-1:genre_term.value', 'genre-1:genre_term.uri', HyacinthMapping::UriMapping::GENRE_MAP)
        csv.value_to_uri('language-1:language_term.value', 'language-1:language_term.uri', HyacinthMapping::UriMapping::LANGUAGE_MAP)

        # Map proquest subjects to fast subjects
        csv.map_subjects_to_fast

        csv.export_to_file
      end
    end
  end
end
