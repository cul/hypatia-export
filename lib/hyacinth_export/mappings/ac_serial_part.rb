module HyacinthExport::Mappings
  module AcSerialPart
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      PREFIX = 'acSerialPart'
      MAP = {
        'abstract'                 => 'abstract-1:abstract_value',
        'genre'                    => 'genre-1:genre_term.value',
        'identifierHDL'            => 'cnri_handle_identifier-1:cnri_handle_identifier_value',
        'ezid'                     => 'doi_identifier-1:doi_identifier_value',
        'language'                 => 'language-1:language_term.value',
        'originInfoDateIssued'     => 'date_issued-1:date_issued_start_value',
        'originInfoPlace'          => 'place_of_origin-1:place_of_origin_value',
        'originInfoPublisher'      => 'publisher-1:publisher_value',
        'title'                    => 'title-1:title_sort_portion',
        'typeOfResource'           => 'type_of_resource-1:type_of_resource_value',
        'relatedItemHost:host_title'          => 'parent_publication-1:parent_publication_title-1:parent_publication_title_sort_portion',
        'relatedItemHost:identifierDOI'       => 'parent_publication-1:parent_publication_doi',
        'relatedItemHost:identifierISSN'      => 'parent_publication-1:parent_publication_issn',
        'relatedItemHost:partDate'            => 'parent_publication-1:parent_publication_date_created_textual',
        'relatedItemHost:partDetailIssue'     => 'parent_publication-1:parent_publication_issue',
        'relatedItemHost:partDetailVolume'    => 'parent_publication-1:parent_publication_volume',
        'relatedItemHost:partExtentPageEnd'   => 'parent_publication-1:parent_publication_page_end',
        'relatedItemHost:partExtentPageStart' => 'parent_publication-1:parent_publication_page_start',
      }

      def from_acserialpart(filename)
        csv = HyacinthExport::CSV.new(filename, prefix: PREFIX)

        csv.delete_columns(%w{
          _hypatia_id tableOfContents
        })

        # Map personal names
        name_matches = csv.headers.map { |h| /#{PREFIX}:(namePersonal-?(\d*)):namePartFamily/.match(h) }.compact
        name_matches.each do |name|
          csv.combine_name("#{PREFIX}:#{name[1]}:namePartGiven", "#{PREFIX}:#{name[1]}:namePartFamily")

          num = name[2].to_i + 1

          # Rename all role row columns
          role_match = csv.headers.map { |h| /#{PREFIX}:#{name[1]}:role-?(\d*)/.match(h) }.compact
          role_match.each do |role|
            new_column = "name-#{num}:name_role-#{role[1].to_i + 1}:name_role_term.value"
            csv.rename_column(role.string, "name-#{num}:name_role-#{role[1].to_i + 1}:name_role_term.value")
            csv.value_to_uri(new_column, new_column.gsub('.value', '.uri'), HyacinthExport::UriMapping::ROLES_MAP)
          end

          # Rename rest of columns
          csv.rename_column("#{PREFIX}:#{name[1]}:nameID", "name-#{num}:name_uni.value")
          csv.rename_column(name.string, "name-#{num}:name_term.value")

          csv.add_name_type(num: num, type: 'personal')

          delete = ['namePartGiven', 'affiliation', 'affiliation-1', 'affiliation-2', 'affiliation-3',
            'affiliationList', 'affiliation-4'].map{ |h| "#{name[1]}:#{h}"}
          csv.delete_columns(delete)
        end



        # Map corporate names
        # corporate_matches = csv.headers.map { |h| /#{PREFIX}:(nameCorporate-?(\d*)):namePart/.match(h) }.compact
        # corporate_matches.each do |name|
        #   num = name_matches.count + name[2].to_i + 1
        #
        #   role_match = csv.headers.map { |h| /#{PREFIX}:#{name[1]}:role-?(\d*)/.match(h) }.compact
        #   role_match.each do |role|
        #     new_column = "name-#{num}:name_role-#{role[1].to_i + 1}:name_role_term.value"
        #     csv.rename_column(role.string, "name-#{num}:name_role-#{role[1].to_i + 1}:name_role_term.value")
        #     csv.value_to_uri(new_column, new_column.gsub('.value', '.uri'), HyacinthExport::UriMapping::ROLES_MAP)
        #   end
        #
        #   csv.rename_column(name.string, "name-#{num}:name_term.value")
        #   csv.add_name_type(num: num, type: 'corporate')
        # end

        # Mapping rest of columns.
        columns_to_add = []
        num_fast = csv.headers.select{ |h| /#{PREFIX}:FAST-?(\d+)?:FASTURI/.match(h) }.count
        csv.headers.each do |header|
          no_prefix_header = header.gsub("#{PREFIX}:", '')

          new_name = if m = /#{PREFIX}:FAST-?(\d*):FASTURI/.match(header)
                      "subject_topic-#{m[1].to_i+1}:subject_topic_term.uri"
                     elsif m = /#{PREFIX}:FAST-?(\d*):FASTSubject/.match(header)
                       "subject_topic-#{m[1].to_i+1}:subject_topic_term.value"
                     elsif m = /#{PREFIX}:subject-?(\d*)/.match(header)
                       num = m[1].to_i + 1 + num_fast
                       columns_to_add.append("subject_topic-#{num}:subject_topic_term.uri")
                       "subject_topic-#{num}:subject_topic_term.value"
                     elsif m = /#{PREFIX}:FASTGeo-?(\d*):GeoURI/.match(header)
                       "subject_geographic-#{m[1].to_i + 1}:subject_geographic_term.uri"
                     elsif m = /#{PREFIX}:FASTGeo-?(\d*):Geo/.match(header)
                       "subject_geographic-#{m[1].to_i + 1}:subject_geographic_term.value"
                     elsif MAP[no_prefix_header] # mapping one-to-one fields
                       MAP[no_prefix_header]
                     else
                       nil
                     end
          csv.rename_column(header, new_name) unless new_name.nil?
        end

        columns_to_add.each { |c| csv.add_column(c) }

        csv.export_to_file
      end
    end
  end
end
