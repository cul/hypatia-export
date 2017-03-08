require 'hyacinth_mapping/uri_mapping'

module HyacinthMapping::TemplateMapping
  module AcPubArticle10
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      PREFIX = 'acPubArticle10'
      MAP = {
        'abstract'                   => 'abstract-1:abstract_value',
        'typeResc'                   => 'type_of_resource-1:type_of_resource_value',
        'originInfoEdition'          => 'edition-1:edition_value',
        'originDateIssued'           => 'date_issued-1:date_issued_start_value',
        'noteField'                  => 'note-1:note_value',
        'genreGenre'                 => 'genre-1:genre_term.value',
        'langLanguageTermText'       => 'language-1:language_term.value',
        'identifierHDL'              => 'cnri_handle_identifier-1:cnri_handle_identifier_value',
        'tiInfoTitle'                => 'title-1:title_sort_portion',
        'identifierDOI'              => 'parent_publication-1:parent_publication_doi',
        'identifier:iDIdentifierHandle'       => 'cnri_handle_identifier-1:cnri_handle_identifier_value',
        'copyEmbargo:copyEmDateEnd'           => 'embargo_release_date-1:embargo_release_date_value',
        'relatedArticleHost:iDIdentifierISSN' => 'parent_publication-1:parent_publication_issn',
        'relatedArticleHost:partDateYear'     => 'parent_publication-1:parent_publication_date_created_textual',
        'relatedArticleHost:partExtentEnd'    => 'parent_publication-1:parent_publication_page_end',
        'relatedArticleHost:partExtentStart'  => 'parent_publication-1:parent_publication_page_start',
        'relatedArticleHost:partIssue'        => 'parent_publication-1:parent_publication_issue',
        'relatedArticleHost:partVolume'       => 'parent_publication-1:parent_publication_volume',
        'relatedArticleHost:tiInfoTitle'      => 'parent_publication-1:parent_publication_title-1:parent_publication_title_sort_portion',
        'nameTypeCorporate:namePart'          => 'name-1:name_term.value',
        'nameTypeCorporate:nameRoleTerm'      => 'name-1:name_role-1:name_role_term.value',
        'nameTypeCorporate:nameRoleTerm-1'    => 'name-1:name_role-2:name_role_term.value'
      }

      # Map CSV headers from acPubArticle10 Hypatia csv to Hyacinth compatible csv
      def from_acpubarticle10(export_filepath, import_filepath)
        csv = HyacinthMapping::CSV.new(export_filepath, import_filepath, prefix: PREFIX)

        csv.delete_columns(%w{
          copyEmbargo:EmRsrcVsbl copyEmbargo:copyEmAccessLevel copyEmbargo:copyEmDateBegin
          copyEmbargo:copyEmIssuedBy copyEmbargo:copyEmNote copyEmbargo:EmPeerReview
          extAuthorRightsStatement identifier:IDidentifierURI locURL identifier:iDIdentifierLocal
          identifier:identifierType physDsExtentFileSize physDsInternetMediaType recInfRecordOrigin
          tiInfoSubTitle Attachments subjectGeoCode relatedArticleHost:identifierDOI
          physDsExtentPages relatedArticleHost:identifier:identifierDOI relatedArticleHost:identifier:identifierType
        })

        to_delete = csv.headers.select { |h| /#{PREFIX}:(copyright|subjectTopicCU(-\d+)?|relatedItemReferences(-\d)?):?.*/.match(h) }
        csv.delete_columns(to_delete, with_prefix: true)

        # Merge issn columns
        csv.merge_columns('relatedArticleHost:iDIdentifierISSN-1', 'relatedArticleHost:iDIdentifierISSN')

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
            'affilAffiliation:affilDeptOther-1', 'affilAffiliation:affilAuIDNAF'
          ].map { |a| "#{name[1]}:#{a}" }
          csv.delete_columns(to_delete)
        end

        # Normalize and merge two DOI columns.
        csv.normalize_doi('acPubArticle10:identifier:IDidentifierDOI')
        csv.normalize_doi('acPubArticle10:identifierDOI')
        csv.merge_columns('identifier:IDidentifierDOI', 'identifierDOI')

        csv.headers.each do |header|
          no_prefix_header = header.gsub("#{PREFIX}:", '')
          if m = /^#{PREFIX}:subjectTopicKeyword-?(\d*)$/.match(header)
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

        csv.map_subjects_to_fast

        # Create Hyacinth compatible csv.
        csv.export_to_file
      end
    end
  end
end
