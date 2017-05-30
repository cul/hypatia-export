module HyacinthMapping::TemplateMapping
  module AcWebpagePart
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      PREFIX = 'acWebpagePart'
      MAP = {
        'abstract'                 => 'abstract-1:abstract_value',
        'genre'                    => 'genre-1:genre_term.value',
        'identifierHDL'            => 'cnri_handle_identifier-1:cnri_handle_identifier_value',
        'ezid'                     => '_doi',
        'originInfoDateIssued'     => 'date_issued-1:date_issued_start_value',
        'originInfoPlace'          => 'place_of_origin-1:place_of_origin_value',
        'originInfoPublisher'      => 'publisher-1:publisher_value',
        'title'                    => 'title-1:title_sort_portion',
        'note'                     => 'note-1:note_value',
        'typeOfResource'           => 'type_of_resource-1:type_of_resource_value',
        'originInfoEdition'        => 'edition-1:edition_value',
        'relatedItemHost:host_title'           => 'parent_publication-1:parent_publication_title-1:parent_publication_title_sort_portion',
        'relatedItemHost:identifierURI'        => 'parent_publication-1:parent_publication_uri',
        'relatedItemHost:originInfoDateIssued' => 'parent_publication-1:parent_publication_date_created_textual',
      }

      def from_acwebpagepart(export_filepath, import_filepath)
        csv = HyacinthMapping::CSV.new(export_filepath, import_filepath, prefix: PREFIX)

        csv.delete_columns(%w{
        })

        # Map personal names
        name_matches = csv.headers.map { |h| /^#{PREFIX}:(namePersonal-?(\d*)):namePartFamily$/.match(h) }.compact
        name_matches.each do |name|
          csv.combine_name("#{PREFIX}:#{name[1]}:namePartGiven", "#{PREFIX}:#{name[1]}:namePartFamily")

          num = name[2].to_i + 1

          # Rename all role row columns
          role_match = csv.headers.map { |h| /^#{PREFIX}:#{name[1]}:role-?(\d*)$/.match(h) }.compact
          role_match.each do |role|
            new_column = "name-#{num}:name_role-#{role[1].to_i + 1}:name_role_term.value"
            csv.rename_column(role.string, "name-#{num}:name_role-#{role[1].to_i + 1}:name_role_term.value")
            csv.map_values_to_uri(new_column, HyacinthMapping::UriMapping::ROLES_MAP)
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
        corporate_matches = csv.headers.map { |h| /^#{PREFIX}:(nameCorporate-?(\d*)):namePart$/.match(h) }.compact
        corporate_matches.each do |name|
          num = name_matches.count + name[2].to_i + 1

          role_match = csv.headers.map { |h| /^#{PREFIX}:#{name[1]}:role-?(\d*)$/.match(h) }.compact
          role_match.each do |role|
            new_column = "name-#{num}:name_role-#{role[1].to_i + 1}:name_role_term.value"
            csv.rename_column(role.string, "name-#{num}:name_role-#{role[1].to_i + 1}:name_role_term.value")
            csv.map_values_to_uri(new_column, HyacinthMapping::UriMapping::ROLES_MAP)
          end

          csv.rename_column(name.string, "name-#{num}:name_term.value")
          csv.add_name_type(num: num, type: 'corporate')
        end

        # Mapping rest of columns.
        num_fast = csv.headers.select{ |h| /^#{PREFIX}:FAST-?(\d+)?:FASTURI$/.match(h) }.count
        csv.headers.each do |header|
          no_prefix_header = header.gsub("#{PREFIX}:", '')

          new_name = if m = /^FAST-?(\d*):FASTURI$/.match(no_prefix_header)
                      "subject_topic-#{m[1].to_i+1}:subject_topic_term.uri"
                    elsif m = /^FAST-?(\d*):FASTSubject$/.match(no_prefix_header)
                       "subject_topic-#{m[1].to_i+1}:subject_topic_term.value"
                     elsif m = /^subject-?(\d*)$/.match(no_prefix_header)
                       num = m[1].to_i + 1 + num_fast
                       "subject_topic-#{num}:subject_topic_term.value"
                     elsif m = /^language-?(\d*)$/.match(no_prefix_header)
                       "language-#{m[1].to_i + 1}:language_term.value"
                     elsif MAP[no_prefix_header] # mapping one-to-one fields
                       MAP[no_prefix_header]
                     else
                       nil
                     end
          csv.rename_column(header, new_name) unless new_name.nil?
        end

        # URI Mappings
        csv.map_values_to_uri('genre-1:genre_term.value', HyacinthMapping::UriMapping::GENRE_MAP)

        csv.headers.select{ |h| /^language-(\d+):language_term.value$/.match(h) }.each do |lang|
          csv.map_values_to_uri(lang, HyacinthMapping::UriMapping::LANGUAGE_MAP)
        end

        # Normalize DOIs
        csv.normalize_doi('_doi')

        # Add 'doi:' in front of every value in _doi
        csv.table.each do |row|
          row['_doi'] = "doi:#{row['_doi']}" unless row['_doi'].blank?
        end

        csv.map_subjects_to_fast

        # Check for empty columns
        empty_columns = csv.empty_columns

        # Delete blank columns that start with the template prefix.
        # These are columns we don't need to bother mapping anyways.
        blank_columns = empty_columns.grep(/^#{PREFIX}:.+$/)
        puts "Empty columns to be removed: \n#{blank_columns.join("\n")}\n\n"
        csv.delete_columns(blank_columns, with_prefix: true)

        csv.export_to_file
      end
    end
  end
end
