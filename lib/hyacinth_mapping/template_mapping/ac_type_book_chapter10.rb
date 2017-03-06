require 'hyacinth_mapping/uri_mapping'

module HyacinthMapping::TemplateMapping
  module AcTypeBookChapter10
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      PREFIX = 'acTypeBookChapter10'
      MAP = {
        'abstract'                   => 'abstract-1:abstract_value',
        'genreGenre'                 => 'genre-1:genre_term.value',
        'identifier:IDidentifierDOI' => 'parent_publication-1:parent_publication_doi',
        'noteField'                  => 'note-1:note_value',
        'originDateIssued'           => 'date_issued-1:date_issued_start_value',
        'tiInfoTitle'                => 'title-1:title_sort_portion',
        'typeResc'                   => 'type_of_resource-1:type_of_resource_value',
        'langLanguageTermText'       => 'language-1:language_term.value',
        'nameTypeCorporate:namePart' => 'name-1:name_term.value',
        'nameTypeCorporate:nameRoleTerm' => 'name-1:name_role-1:name_role_term.value',
        'iDIdentifierHandle'         => 'cnri_handle_identifier-1:cnri_handle_identifier_value',
        'relatedBkChptrHost:originDateIssued' => 'parent_publication-1:parent_publication_date_created_textual',
        'relatedBkChptrHost:originPlaceText' => 'parent_publication-1:parent_publication_place_of_origin',
        'relatedBkChptrHost:originPublisher' => 'parent_publication-1:parent_publication_publisher',
        'relatedBkChptrHost:partExtentEnd' => 'parent_publication-1:parent_publication_page_start',
        'relatedBkChptrHost:partExtentStart' => 'parent_publication-1:parent_publication_page_end',
        'relatedBkChptrHost:partVolume' => 'parent_publication-1:parent_publication_volume',
        'relatedBkChptrHost:tiInfoTitle' => 'parent_publication-1:parent_publication_title-1:parent_publication_title_sort_portion',
        'relatedBkChptrHost:iDIdentifierISBN' => 'parent_publication-1:parent_publication_isbn'
      }

      def from_actypebookchapter10(export_filepath, import_filepath)
        csv = HyacinthMapping::CSV.new(export_filepath, import_filepath, prefix: PREFIX)

        csv.delete_columns(%w{
          Attachments copyEmbargo:EmRsrcVsbl copyEmbargo:copyEmAccessLevel copyEmbargo:copyEmDateBegin
          copyEmbargo:copyEmDateEnd copyEmbargo:copyEmIssuedBy copyEmbargo:copyEmNote copyright:accCCStatements
          copyright:copyCopyStatement extAuthorRightsStatement identifier:IDidentifierURI
          locURL nameAffil-1:affilAffiliation:affilAuIDLocal nameTypeConference:namePart
          nameTypeConference:nameRoleTerm noteRef physDsExtentFileSize physDsInternetMediaType
          recInfRecordOrigin  relatedBkChptrHost:acNamePersonalShort-1:namePartDate
          relatedBkChptrHost:acNamePersonalShort:namePartDate relatedBkChptrHost:identifierDOI
          relatedBkChptrHost:originEdition subjectGeoCode
        })

        # Map parent publication authors. One parent publication per record, can have multiple authors.
        parent_pub_authors = csv.headers.map { |h| /#{PREFIX}:(relatedBkChptrHost:acNamePersonalShort-?(\d*)):namePartFamily/.match(h) }.compact
        parent_pub_authors.each do |name|
          csv.combine_name("#{PREFIX}:#{name[1]}:namePartGiven", "#{PREFIX}:#{name[1]}:namePartFamily")

          num = name[2].to_i + 1

          name_value = "parent_publication-1:parent_publication_name-#{num}:parent_publication_name_term.value"
          csv.rename_column(name.string, name_value)

          # Role term
          role_column = "parent_publication-1:parent_publication_name-#{num}:parent_publication_name_role-1:parent_publication_name_role_term.value"
          csv.rename_column("#{PREFIX}:#{name[1]}:nameRoleTerm", role_column)
          csv.value_to_uri(role_column, role_column.gsub('.value', '.uri'), HyacinthMapping::UriMapping::ROLES_MAP)

          name_type = "parent_publication-1:parent_publication_name-#{num}:parent_publication_name_term.name_type"
          csv.add_column(name_type)
          csv.table.each do |row|
            unless row[name_value].blank?
             row[name_type] = 'personal'
            end
          end

           # Delete extra name columns no longer needed
           csv.delete_columns(["#{name[1]}:namePartDate", "#{name[1]}:namePartGiven"])
        end

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
          csv.value_to_uri(role_column, role_column.gsub('.value', '.uri'), HyacinthMapping::UriMapping::ROLES_MAP)

          csv.add_name_type(num: num, type: 'personal')

          # Delete extra name columns no longer needed
          to_delete = [
            'affilDept', 'affilDept-1', 'affilDept-2', 'affilDept-3', 'namePartGiven', 'affilDept', 'namePartDate',
            'affilAffiliation:affilAuIDLocal', 'affilAffiliation:affilEmail', 'affilAffiliation:originCountry',
            'affilAffiliation:affilOrganization', 'affilAffiliation:affilDept', 'affilAffiliation:affilDeptOther',
            'affilAffiliation:affilDeptOther-1', 'affilAffiliation:affilAuIDNAF','affilAffiliation:affilDeptOther-2',
          ].map { |a| "#{name[1]}:#{a}" }
          csv.delete_columns(to_delete)
        end

        csv.merge_columns('identifier:iDIdentifierHandle', 'iDIdentifierHandle')

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
        csv.value_to_uri('genre-1:genre_term.value', 'genre-1:genre_term.uri', HyacinthMapping::UriMapping::GENRE_MAP)
        csv.value_to_uri('language-1:language_term.value', 'language-1:language_term.uri', HyacinthMapping::UriMapping::LANGUAGE_MAP)

        # Add type for first (corporate) name.
        csv.add_name_type(num: 1, type: 'corporate')

        # Add role uri for corporate name.
        csv.value_to_uri("name-1:name_role-1:name_role_term.value", "name-1:name_role-1:name_role_term.uri", HyacinthMapping::UriMapping::ROLES_MAP)
        csv.value_to_uri("name-1:name_role-2:name_role_term.value", "name-1:name_role-2:name_role_term.uri", HyacinthMapping::UriMapping::ROLES_MAP)

        # Map proquest subjects to fast subjects
        csv.map_subjects_to_fast

        csv.export_to_file
      end
    end
  end
end
