require 'hyacinth_mapping/uri_mapping'

module HyacinthMapping::TemplateMapping
  module AcPubArticle
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      PREFIX = 'acPubArticle'
      MAP = {
        'abstract'             => 'abstract-1:abstract_value',
        'genreGenre'           => 'genre-1:genre_term.value',
        'identifierHDL'        => 'cnri_handle_identifier-1:cnri_handle_identifier_value',
        'langLanguageTermText' => 'language-1:language_term.value',
        'noteField'            => 'note-1:note_value',
        'originDateIssued'     => 'date_issued-1:date_issued_start_value',
        'tiInfoTitle'          => 'title-1:title_sort_portion',
        'relatedArticleHost:identifierDOI'    => 'parent_publication-1:parent_publication_doi',
        'relatedArticleHost:iDIdentifierISSN' => 'parent_publication-1:parent_publication_issn',
        'relatedArticleHost:partExtentEnd'    => 'parent_publication-1:parent_publication_page_end',
        'relatedArticleHost:partExtentStart'  => 'parent_publication-1:parent_publication_page_start',
        'relatedArticleHost:partIssue'        => 'parent_publication-1:parent_publication_issue',
        'relatedArticleHost:partVolume'       => 'parent_publication-1:parent_publication_volume',
        'relatedArticleHost:tiInfoTitle'      => 'parent_publication-1:parent_publication_title-1:parent_publication_title_sort_portion',
        'typeResc'                            => 'type_of_resource-1:type_of_resource_value',
      }

      def from_acpubarticle(export_filepath, import_filepath)
        csv = HyacinthMapping::CSV.new(export_filepath, import_filepath, prefix: PREFIX)

        csv.delete_columns(%w{
          Attachments copyEmbargo:EmPeerReview copyEmbargo:EmRsrcVsbl copyEmbargo:copyEmAccessLevel
          copyEmbargo:copyEmDateBegin copyEmbargo:copyEmDateEnd copyEmbargo:copyEmIssuedBy
          copyEmbargo:copyEmNote copyright:accCCStatements copyright:copyCopyNotice
          copyright:copyCopyStatement copyright:copyCopyStatement-1 copyright:copyCopyStatus copyright:copyCountry
          copyright:copyPubStatus copyright:copyRightsContact copyright:copyRightsName
          copyright:copyRightsNote copyright:copyYear extAuthorRightsStatement
          identifier:IDidentifierDOI identifier:IDidentifierURI identifier:iDIdentifierHandle
          identifier:iDIdentifierLocal identifierDOI locURL physDsExtentFileSize
          physDsExtentPages physDsInternetMediaType recInfRecordOrigin physDsInternetMediaType-1
          relatedArticleHost:partDateYear subjectGeoCode tableOfContents subjectGeoCode-1
          relatedArticleHost-1:iDIdentifierISSN relatedArticleHost-1:partDateYear relatedArticleHost-1:partExtentEnd
          relatedArticleHost-1:partExtentStart relatedArticleHost-1:partIssue relatedArticleHost-1:partVolume
          relatedArticleHost-1:tiInfoTitle genreGenre-1 langLanguageTermText-1 noteField-1 typeResc-1
        })

        # Append title and subtitle
        csv.append_columns('acPubArticle:tiInfoTitle', 'acPubArticle:tiInfoSubTitle', seperator: ': ')

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
            'affilAffiliation:affilAuIDLocal', 'affilAffiliation:affilEmail', 'affilAffiliation:affilEmail-1',
            'affilAffiliation:originCountry', 'affilAffiliation-1:originCountry', 'affilAffiliation-1:affilOrganization-1',
            'affilAffiliation-1:affilOrganization', 'affilAffiliation-1:affilEmail-1', 'affilAffiliation-1:affilEmail',
            'affilAffiliation:affilOrganization', 'affilAffiliation:affilOrganization-1', 'affilAffiliation-1:affilDeptOther-1',
            'affilAffiliation-1:affilDeptOther', 'affilAffiliation-1:affilDept-1', 'affilAffiliation-1:affilDept',
            'affilAffiliation:affilOrganization-2', 'affilAffiliation:affilDept', 'affilAffiliation:affilDept-1',
            'affilAffiliation:affilDept-2', 'affilAffiliation:affilDeptOther', 'affilAffiliation-1:affilAuIDUNI',
            'affilAffiliation:affilDeptOther-1', 'affilAffiliation:affilAuIDNAF', 'affilAffiliation:affilDeptOther-2',
            'affiliation', 'nameID', 'affilAffiliation:affilDept-1', 'nameRoleTerm-1', 'affilAffiliation-1:affilAuIDNAF',
            'affilAffiliation-1:affilAuIDLocal', 'affilAffiliation:affilDept-3'
          ].map { |a| "#{name[1]}:#{a}" }
          csv.delete_columns(to_delete)
        end

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

        # Map proquest subjects to fast subjects
        csv.map_subjects_to_fast

        csv.export_to_file
      end
    end
  end
end
