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
        first = "#{prefix}:#{name_prefix}:namePartGiven"
        last = "#{prefix}:#{name_prefix}:namePartFamily"

        # Join first and last name fields.
        csv.table.each do |row|
          if (last_name = row[last]) && (first_name = row[first])
            row[last] = "#{last_name}, #{first_name}"
          end
        end

        # Translate role term to uri
        csv.value_to_uri("#{prefix}:#{name_prefix}:nameRoleTerm", "#{prefix}:#{name_prefix}:nameRoleURI", UriMapping::ROLES_MAP)

        csv.merge_columns("#{name_prefix}:affilAffiliation:affilAuIDUNI", "#{name_prefix}:affilAuIDUNI")

        # Delete extra name columns no longer needed
        to_delete = [
          'affilDept', 'affilDept-1', 'affilDept-2', 'affilDept-3', 'namePartGiven', 'affilDept', 'namePartDate', 'affilAffiliation:affilAuIDLocal',
          'affilAffiliation:affilEmail', "affilAffiliation:originCountry", 'affilAffiliation:affilOrganization',
          'affilAffiliation:affilDept', 'affilAffiliation:affilDeptOther'
        ].map { |a| "#{name_prefix}:#{a}" }

        columns_to_delete.concat(to_delete)
      end

      # Merge two DOI columns.
      csv.merge_columns('identifier:IDidentifierDOI', 'identifierDOI')

      # Delete columns that are no necessary for export.
      csv.delete_columns(columns_to_delete)

      map = HyacinthExport::Fields::MAP[prefix]

      csv.headers.each do |header|
        no_prefix_header = header.gsub("#{prefix}:", '')
        if m = /#{prefix}:nameAffil-(\d+):(\w+)/.match(header)
          name_field_map = {
            'namePartFamily' => 'name_term.value',
            'nameRoleTerm'   => 'name_role-1:name_role_term.value',
            'nameRoleURI'    => 'name_role-1:name_role_term.uri',
            'affilAuIDUNI'   => 'name_uni.value'
          }
          if field = name_field_map[m[2]]
            num = m[1].to_i + 1 # increment by 1
            csv.rename_column(header, "name-#{num+1}:#{field}")
          end
        elsif m = /#{prefix}:subjectTopicKeyword-(\d+)/.match(header)
          csv.rename_column(header, "subject_topic-#{m[1]}:subject_topic_term.value")
        elsif map[no_prefix_header] # mapping one-to-one fields
          csv.rename_column(header, map[no_prefix_header])
        end
      end

      # normalize doi in 'identifierDOI' => 'doi_identifier-1:doi_identifier_value'
      csv.table.each do |row|
        doi = row['doi_identifier-1:doi_identifier_value']
        if m = /http\:\/\/dx.doi.org\/(.+)/.match(doi)
          row['doi_identifier-1:doi_identifier_value'] = m[1]
        end
      end

      # Map role terms from values to uris
      csv.value_to_uri('genre-1:genre_term.value', 'genre-1:genre_term.uri', UriMapping::GENRE_MAP)
      csv.value_to_uri('language-1:language_term.value', 'language-1:language_term.uri', UriMapping::LANGUAGE_MAP)
      # Map corporate role term (first name)

      # converter
      csv.value_to_uri('name-1:name_role-1:name_role_term.value', 'name-1:name_role-1:name_role_term.uri', UriMapping::ROLES_MAP)

      # Add name type personal/corporate for /name-\d/
      csv.headers.each do |header|
        m = /name-(\d+).name_term.value/.match header
        next if m.nil?
        type = (m[1].to_i == 1) ? 'corporate' : 'personal'
        csv.add_column("name-#{m[1]}:name_term.name_type")
        csv.table.each do |row|
          unless row["name-#{m[1]}:name_term.value"].blank?
            row["name-#{m[1]}:name_term.name_type"] = type
          end
        end
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
