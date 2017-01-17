require 'hyacinth_export/fields'
require 'hyacinth_export/csv'

module HyacinthExport
  module MapHeaders
    # Map CSV headers from acPubArticle10 to Hyacinth compatible csv
    def self.from_acpubarticle10() #param = filenames
      filename = File.join(Rails.root, 'tmp', 'data', 'test-export-values.csv')
      prefix = 'acPubArticle10' # Template prefix
      csv = HyacinthExport::CSV.new(filename, prefix: prefix)

      columns_to_delete = %w{
        copyEmbargo:EmRsrcVsbl copyEmbargo:copyEmAccessLevel copyEmbargo:copyEmDateBegin
        copyEmbargo:copyEmIssuedBy copyEmbargo:copyEmNote copyright:accCCStatements Attachments
        copyright:copyCopyStatement extAuthorRightsStatement identifier:IDidentifierURI locURL
        physDsExtentFileSize physDsInternetMediaType recInfRecordOrigin relatedItemReferences:locURL
        relatedItemReferences:noteField relatedItemReferences:tiInfoTitle subjectGeoCode subjectTopicKeyword
      }

      name_headers = csv.headers.map{ |h| /#{prefix}:(nameAffil-\d+):namePartGiven/.match h }.compact.map{ |m| m[1] }
      name_headers.each do |name_prefix|
        first_index = csv.headers.find_index("#{prefix}:#{name_prefix}:namePartGiven")
        last_index = csv.headers.find_index("#{prefix}:#{name_prefix}:namePartFamily")

        # Join first and last name fields.
        (1..csv.array.length-1).each do |row|
          if (last = csv.array[row][last_index]) && (first = csv.array[row][first_index])
            csv.array[row][last_index] = "#{last}, #{first}"
          end
        end

        # Translate role term to uri
        csv.value_to_uri("#{prefix}:#{name_prefix}:nameRoleTerm", "#{prefix}:#{name_prefix}:nameRoleURI", UriMapping::ROLES_MAP)

        csv.merge_columns("#{name_prefix}:affilAffiliation:affilAuIDUNI", "#{name_prefix}:affilAuIDUNI")

        # Delete extra name columns no longer needed
        to_delete = [
          'affilDept', 'namePartGiven', 'affilDept', 'namePartDate', 'affilAffiliation:affilAuIDLocal',
          'affilAffiliation:affilEmail', "affilAffiliation:originCountry", 'affilAffiliation:affilOrganization',
          'affilAffiliation:affilDept', 'affilAffiliation:affilDeptOther'
        ].map { |a| "#{name_prefix}:#{a}" }

        columns_to_delete.concat(to_delete)
      end

      # Add corporate as nameAffil-(n+1)

      # Merge two DOI columns.
      csv.merge_columns('identifier:IDidentifierDOI', 'identifierDOI')

      # Delete columns that are no necessary for export.
      csv.delete_columns(columns_to_delete)

      map = HyacinthExport::Fields::MAP[prefix]

      csv.array.first.map! do |header|
        no_prefix_header = header.gsub("#{prefix}:", '')
        if m = /#{prefix}:nameAffil-(\d+):(\w+)/.match(header)
          num = m[1].to_i + 1
          field = case m[2]
                    when 'namePartFamily'
                      'name_term.value'
                    when 'nameRoleTerm'
                      'name_role-1:name_role_term.value'
                    when 'nameRoleURI'
                      'name_role-1:name_role_term.uri'
                    when 'affilAuIDUNI'
                      'name_uni.value'
                    else
                      ''
                    end
            "name-#{num+1}:#{field}"
        elsif m = /#{prefix}:subjectTopicKeyword-(\d+)/.match(header)
          "subject_topic-#{m[1]}:subject_topic_term.value"
        elsif map[no_prefix_header] # mapping one-to-one fields
          map[no_prefix_header]
        else
          header
        end
      end

      # normalize doi in 'identifierDOI' => 'doi_identifier-1:doi_identifier_value',

      # Map role terms from values to uris
      csv.value_to_uri('genre-1:genre_term.value', 'genre-1:genre_term.uri', UriMapping::GENRE_MAP)
      csv.value_to_uri('language-1:language_term.value', 'language-1:language_term.uri', UriMapping::LANGUAGE_MAP)
      # Map corporate role term (first name)
      csv.value_to_uri('name-1:name_role-1:name_role_term.value', 'name-1:name_role-1:name_role_term.uri', UriMapping::ROLES_MAP)

      # find all name headers and map to the correct uris
      headers.each do |name_prefix|
      end


      # Create Hyacinth compatible csv.
      csv.export_to_file
    end

    def self.acedt
      filename = File.join(Rails.root, 'tmp', 'data', 'test-export-values.csv')
      prefix = 'acETD' # Template prefix
      csv = HyacinthExport::CSV.new(filename, prefix: prefix)

      columns_to_delete = %w{
        copyright:copyrightNotice copyright:creativeCommonsLicense tableOfContents
        namePersonal:affiliation namePersonal:affiliation-1 namePersonal:affiliation-2
        namePersonal:affiliationList
      }
      csv.delete_columns(columns_to_delete)

      map = HyacinthExport::Fields::MAP[prefix]

      csv.array.first.map! do |header|
        no_prefix_header = header.gsub(prefix, '')
        if map[no_prefix_header] # mapping one-to-one fields
          map[no_prefix_header]
        else
          header
        end
      end

      csv.export_to_file(mapped_csv_filename)
    end
  end
end
