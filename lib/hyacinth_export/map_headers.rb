require 'hyacinth_export/fields'
require 'hyacinth_export/csv'

module HyacinthExport
  module MapHeaders
    # Map CSV headers from acPubArticle10 Hypatia csv to Hyacinth compatible csv
    def self.from_acpubarticle10(filename)
      # filename = File.join(Rails.root, 'tmp', 'data', 'test-export-values.csv')
      prefix = 'acPubArticle10' # Template prefix
      csv = HyacinthExport::CSV.new(filename, prefix: prefix)

      columns_to_delete = %w{
        extAuthorRightsStatement identifier:IDidentifierURI locURL identifier:iDIdentifierLocal
        identifier:identifierType nameAffil-2:affilAffiliation:affilAuIDNAF
        physDsExtentFileSize physDsInternetMediaType recInfRecordOrigin tiInfoSubTitle Attachments
        subjectGeoCode subjectTopicKeyword relatedArticleHost:identifierDOI nameAffil-1:affilAffiliation:affilAuIDNAF
        nameAffil-2:affilAffiliation:affilAuIDNAF nameTypeCorporate:nameRoleTerm-1
        nameTypeCorporate:nameRoleTerm-2 physDsExtentPages relatedArticleHost:identifier:identifierDOI relatedArticleHost:identifier:identifierType
      }

      to_delete = csv.headers.select { |h| /#{prefix}:(copyEmbargo|copyright|subjectTopicCU-\d+|relatedItemReferences(-\d)?):?.*/.match(h) }
      to_delete.map! { |h| /#{prefix}:(.*)/.match(h)[1] }
      columns_to_delete.concat(to_delete)

      name_headers = csv.headers.map{ |h| /#{prefix}:(nameAffil(-\d+)?):namePartGiven/.match h }.compact.map{ |m| m[1] }
      name_headers.each do |name_prefix|
        first = "#{prefix}:#{name_prefix}:namePartGiven"
        last = "#{prefix}:#{name_prefix}:namePartFamily"

        # Join first and last name fields.
        csv.combine_name(first, last)

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

      map = HyacinthExport::Fields::MAP[prefix]

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
        elsif map[no_prefix_header] # mapping one-to-one fields
          csv.rename_column(header, map[no_prefix_header])
        end
      end

      # Map role terms from values to uris
      csv.value_to_uri('genre-1:genre_term.value', 'genre-1:genre_term.uri', UriMapping::GENRE_MAP)
      csv.value_to_uri('language-1:language_term.value', 'language-1:language_term.uri', UriMapping::LANGUAGE_MAP)

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

        csv.value_to_uri("name-#{num}:name_role-1:name_role_term.value", "name-#{num}:name_role-1:name_role_term.uri", UriMapping::ROLES_MAP)
      end

      # Create Hyacinth compatible csv.
      csv.export_to_file
    end


    # Map CSV headers from acETD Hypatia csv to Hyacinth compatible csv
    def self.from_acetd
      filename = File.join(Rails.root, 'tmp', 'data', 'test-export-values.csv')
      prefix = 'acETD' # Template prefix
      csv = HyacinthExport::CSV.new(filename, prefix: prefix)

      columns_to_delete = %w{
        copyright:copyrightNotice copyright:creativeCommonsLicense tableOfContents
        namePersonal:affiliation namePersonal:affiliation-1 namePersonal:affiliation-2
        namePersonal:affiliationList
      }
      csv.delete_columns(columns_to_delete)

      # # Get all the number of fast subjects and proquest subjects
      subject_headers = csv.headers.select{ |h| /#{prefix}:FAST-(\d+):FASTURI|#{prefix}:subject-?(\d*)/.match(h) }
      (1..subject_headers.count).each do |num|
        csv.add_column("subject_topic-#{num}:subject_topic_term.value")
        csv.add_column("subject_topic-#{num}:subject_topic_term.uri")
      end

      csv.table.each do |row|
        subjects = []
        subject_headers.each do |s|
          if m = /#{prefix}:FAST-(\d+):FASTURI/.match(s)
            subjects << { value: row[s.gsub('FASTURI', 'FASTSubject')], uri: row[s]}
          else
            subjects << { value: row[s], uri: nil }
          end
        end
        subjects.delete_if { |a| a[:value].blank? && a[:uri].blank? }

        subjects.each_with_index do |hash, index|
          row["subject_topic-#{index+1}:subject_topic_term.value"] = hash[:value]
          row["subject_topic-#{index+1}:subject_topic_term.uri"] = hash[:uri]
        end
      end

      csv.delete_columns(subject_headers, with_prefix: true) #add value fields of Fast to be deleted

      # make same number of new columns with the new names
      # For each row go through an move the subjects

      map = HyacinthExport::Fields::MAP[prefix]

      csv.headers.each do |header|
        no_prefix_header = header.gsub("#{prefix}:", '')

        if map[no_prefix_header] # mapping one-to-one fields
          csv.rename_column(header, map[no_prefix_header])
        end
      end

      #subject_headers = csv.headers.select{ |h| /#{prefix}:FAST-(\d+):FASTURI|#{prefix}:subject-?(\d*)/.match(h) }

      csv.export_to_file
    end
  end
end
