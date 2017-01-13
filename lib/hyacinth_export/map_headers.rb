require 'hyacinth_export/fields'
require 'hyacinth_export/csv'

module HyacinthExport
  module MapHeaders
    # Map CSV headers from acPubArticle10 to Hyacinth compatible csv
    def self.from_acpubarticle10() #param = filenames
      filename = File.join(Rails.root, 'tmp', 'data', 'test-export-values.csv')
      prefix = 'acPubArticle10:' # Template prefix
      csv = HyacinthExport::CSV.new(filename)

      columns_to_delete = %w{
        acPubArticle10:copyEmbargo:EmRsrcVsbl acPubArticle10:copyEmbargo:copyEmAccessLevel
        acPubArticle10:copyEmbargo:copyEmDateBegin acPubArticle10:copyEmbargo:copyEmIssuedBy
        acPubArticle10:copyEmbargo:copyEmNote acPubArticle10:copyright:accCCStatements
        acPubArticle10:copyright:copyCopyStatement acPubArticle10:extAuthorRightsStatement
        acPubArticle10:identifier:IDidentifierURI acPubArticle10:locURL
        acPubArticle10:physDsExtentFileSize acPubArticle10:physDsInternetMediaType
        acPubArticle10:recInfRecordOrigin acPubArticle10:relatedItemReferences:locURL acPubArticle10:relatedItemReferences:noteField
        acPubArticle10:relatedItemReferences:tiInfoTitle acPubArticle10:subjectGeoCode acPubArticle10:subjectTopicKeyword
      }

      name_headers = csv.headers.map{ |h| /#{prefix}(nameAffil-\d+):namePartGiven/.match h }.compact.map{ |m| m[1] }
      name_headers.each do |name_prefix|
        first_index = csv.headers.find_index("#{prefix}#{name_prefix}:namePartGiven")
        last_index = csv.headers.find_index("#{prefix}#{name_prefix}:namePartFamily")

        # Join first and last name fields.
        (1..csv.array.length-1).each do |row|
          if (last = csv.array[row][last_index]) && (first = csv.array[row][first_index])
            csv.array[row][last_index] = "#{last}, #{first}"
          end
        end

        # Translate role term to uri
        csv.value_to_uri("#{prefix}#{name_prefix}:nameRoleTerm", "#{prefix}#{name_prefix}:nameRoleURI", HyacinthExport::UriMapping::ROLES_MAP)

        # Delete extra name columns no longer needed
        to_delete = [
          'affilDept', 'namePartGiven', 'affilDept', 'namePartDate', 'affilAffiliation:affilAuIDLocal',
          'affilAffiliation:affilEmail', "affilAffiliation:originCountry", 'affilAffiliation:affilOrganization'
        ].map { |a| "#{prefix}#{name_prefix}:#{a}" }

        columns_to_delete.concat(to_delete)
      end

      # Add corporate as nameAffil-(n+1)

      # Delete columns that are no necessary for export.
      csv.delete_columns(columns_to_delete)

      map = HyacinthExport::Fields::MAP['acPubArticle10']

      csv.array.first.map! do |header|
        no_prefix_header = header.gsub(prefix, '')
        if m = /#{prefix}nameAffil-(\d+):namePartFamily/.match(header)
          "name-#{m[1]}:name_term.value"
        elsif m = /#{prefix}nameAffil-(\d+):nameRoleTerm/.match(header)
          "name-#{m[1]}:name_role-1:name_role_term.value"
        elsif m = /#{prefix}nameAffil-(\d+):nameRoleURI/.match(header)
          "name-#{m[1]}:name_role-1:name_role_term.uri"
        elsif m = /#{prefix}nameAffil-(\d+):affilAuIDUNI/.match(header)
          "name-#{m[1]}:name_uni.value"
        elsif m = /#{prefix}subjectTopicKeyword-(\d+)/.match(header)
          "subject_topic-#{m[1]}:subject_topic_term.value"
        elsif map[no_prefix_header] # mapping one-to-one fields
          map[no_prefix_header]
        else
          header
        end
      end

      # normalize all doi fields to one column?


      # Map role terms from values to uris
      csv.value_to_uri('genre-1:genre_term.value', 'genre-1:genre_term.uri', HyacinthExport::UriMapping::GENRE_MAP)
      csv.value_to_uri('language-1:language_term.value', 'language-1:language_term.uri', HyacinthExport::UriMapping::LANGUAGE_MAP)

      # Create Hyacinth compatible csv.
      mapped_csv_filename = File.join(Rails.root, 'tmp', 'data', "#{prefix.gsub(':', '')}-export-to-hypatia.csv")
      csv.export_to_file(mapped_csv_filename)

      return mapped_csv_filename
    end
  end
end
