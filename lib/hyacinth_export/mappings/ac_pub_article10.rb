require 'hyacinth_export/uri_mapping'

module HyacinthExport::Mappings
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
        'nameTypeCorporate:nameRoleTerm'      => 'name-1:name_role-1:name_role_term.value'
      }

      # Map CSV headers from acPubArticle10 Hypatia csv to Hyacinth compatible csv
      def from_acpubarticle10(filename)
        prefix = PREFIX # Template prefix
        csv = HyacinthExport::CSV.new(filename, prefix: prefix)

        columns_to_delete = %w{
          copyEmbargo:EmRsrcVsbl copyEmbargo:copyEmAccessLevel copyEmbargo:copyEmDateBegin
          copyEmbargo:copyEmIssuedBy copyEmbargo:copyEmNote
          extAuthorRightsStatement identifier:IDidentifierURI locURL identifier:iDIdentifierLocal
          identifier:identifierType nameAffil-2:affilAffiliation:affilAuIDNAF
          physDsExtentFileSize physDsInternetMediaType recInfRecordOrigin tiInfoSubTitle Attachments
          subjectGeoCode subjectTopicKeyword relatedArticleHost:identifierDOI nameAffil-1:affilAffiliation:affilAuIDNAF
          nameAffil-2:affilAffiliation:affilAuIDNAF nameTypeCorporate:nameRoleTerm-1
          nameTypeCorporate:nameRoleTerm-2 physDsExtentPages relatedArticleHost:identifier:identifierDOI relatedArticleHost:identifier:identifierType
        }

        to_delete = csv.headers.select { |h| /#{prefix}:(copyright|subjectTopicCU-\d+|relatedItemReferences(-\d)?):?.*/.match(h) }
        to_delete.map! { |h| /#{prefix}:(.*)/.match(h)[1] }
        columns_to_delete.concat(to_delete)

        name_headers = csv.headers.map{ |h| /#{prefix}:(nameAffil-\d+):namePartGiven/.match h }.compact.map{ |m| m[1] }
        name_headers.each do |name_prefix|
          # Join first and last name fields.
          csv.combine_name("#{prefix}:#{name_prefix}:namePartGiven", "#{prefix}:#{name_prefix}:namePartFamily")

          csv.merge_columns("#{name_prefix}:affilAffiliation:affilAuIDUNI", "#{name_prefix}:affilAuIDUNI")

          # Delete extra name columns no longer needed
          to_delete = [
            'affilDept', 'affilDept-1', 'affilDept-2', 'affilDept-3', 'namePartGiven', 'affilDept', 'namePartDate', 'affilAffiliation:affilAuIDLocal',
            'affilAffiliation:affilEmail', "affilAffiliation:originCountry", 'affilAffiliation:affilOrganization',
            'affilAffiliation:affilDept', 'affilAffiliation:affilDeptOther'
          ].map { |a| "#{name_prefix}:#{a}" }

          columns_to_delete.concat(to_delete)
        end

        # Normalize and merge two DOI columns.
        # Normalize doi in acPubArticle10:identifier:IDidentifierDOI
        csv.normalize_doi('acPubArticle10:identifier:IDidentifierDOI')
        csv.normalize_doi('acPubArticle10:identifierDOI')
        csv.merge_columns('identifier:IDidentifierDOI', 'identifierDOI')

        # Delete columns that are no necessary for export.
        csv.delete_columns(columns_to_delete)

        csv.headers.each do |header|
          no_prefix_header = header.gsub("#{prefix}:", '')
          if m = /#{prefix}:nameAffil-(\d+):(\w+)/.match(header)
            name_field_map = {
              'namePartFamily' => 'name_term.value',
              'nameRoleTerm'   => 'name_role-1:name_role_term.value',
              'affilAuIDUNI'   => 'name_uni.value'
            }
            if field = name_field_map[m[2]]
              num = m[1].to_i + 1 # increment by 1
              csv.rename_column(header, "name-#{num}:#{field}")
            end
          elsif m = /#{prefix}:subjectTopicKeyword-(\d+)/.match(header)
            csv.rename_column(header, "subject_topic-#{m[1]}:subject_topic_term.value")
          elsif MAP[no_prefix_header] # mapping one-to-one fields
            csv.rename_column(header, MAP[no_prefix_header])
          end
        end

        # Map role terms from values to uris
        csv.value_to_uri('genre-1:genre_term.value', 'genre-1:genre_term.uri', HyacinthExport::UriMapping::GENRE_MAP)
        csv.value_to_uri('language-1:language_term.value', 'language-1:language_term.uri', HyacinthExport::UriMapping::LANGUAGE_MAP)

        num_names = csv.headers.select{ |h| /name-(\d+).name_term.value/.match(h) }.count

        # Merging in nameAffil
        csv.combine_name('acPubArticle10:nameAffil:namePartGiven', 'acPubArticle10:nameAffil:namePartFamily')
        csv.table.each do |row|
          name = row['acPubArticle10:nameAffil:namePartFamily']
          next if name.blank?
          uni = row['acPubArticle10:nameAffil:affilAuIDUNI']
          role_value = row['acPubArticle10:nameAffil:nameRoleTerm']

          (2..num_names).each do |num|
            if row["name-#{num}:name_term.value"].blank?
              row["name-#{num}:name_term.value"] = name
              row["name-#{num}:name_uni.value"] = uni
              row["name-#{num}:name_role-1:name_role_term.value"] = role_value
              break
              # add data in this column
            else num == num_names # if last one, create new row
              puts 'creating new columns'
              csv.add_column("name-#{num+1}:name_term.value")
              csv.add_column("name-#{num+1}:name_uni.value")
              csv.add_column("name-#{num+1}:name_role-1:name_role_term.value")
              row["name-#{num+1}:name_term.value"] = name
              row["name-#{num+1}:name_uni.value"] = uni
              row["name-#{num+1}:name_role-1:name_role_term.value"] = role_value
            end
          end
        end
        csv.delete_columns(csv.headers.select{ |h| /acPubArticle10:nameAffil:.*/.match(h) }, with_prefix: true)

        # Add name type personal/corporate for /name-\d/
        # Convert role term to uri for all names
        (1..num_names).each do |num|
          type = (num == 1) ? 'corporate' : 'personal'
          csv.add_column("name-#{num}:name_term.name_type")
          csv.table.each do |row|
            unless row["name-#{num}:name_term.value"].blank?
              row["name-#{num}:name_term.name_type"] = type
            end
          end

          csv.value_to_uri("name-#{num}:name_role-1:name_role_term.value", "name-#{num}:name_role-1:name_role_term.uri", HyacinthExport::UriMapping::ROLES_MAP)
        end

        # Create Hyacinth compatible csv.
        csv.export_to_file
      end
    end
  end
end
