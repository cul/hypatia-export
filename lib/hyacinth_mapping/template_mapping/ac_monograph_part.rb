module HyacinthMapping::TemplateMapping
  module AcMonographPart
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      PREFIX = 'acMonographPart'
      MAP = {
        'abstract'                 => 'abstract-1:abstract_value',
        'genre'                    => 'genre-1:genre_term.value',
        'identifierHDL'            => 'cnri_handle_identifier-1:cnri_handle_identifier_value',
        'ezid'                     => '_doi',
        'originInfoDateIssued'     => 'date_issued-1:date_issued_start_value',
        'originInfoEdition'        => 'edition-1:edition_value',
        'title'                    => 'title-1:title_sort_portion',
        'note'                     => 'note-1:note_value',
        'typeOfResource'           => 'type_of_resource-1:type_of_resource_value',
        'tombstone:tombstoneList'  => 'restriction_on_access-1:restriction_on_access_value',
        'relatedItemHost:identifierDOI'        => 'parent_publication-1:parent_publication_doi',
        'relatedItemHost:identifierISBN'       => 'parent_publication-1:parent_publication_isbn',
        'relatedItemHost:originInfoDateIssued' => 'parent_publication-1:parent_publication_date_created_textual',
        'relatedItemHost:identifierURI'        => 'parent_publication-1:parent_publication_uri',
        'relatedItemHost:originInfoEdition'    => 'parent_publication-1:parent_publication_edition',
        'relatedItemHost:originInfoPlace'      => 'parent_publication-1:parent_publication_place_of_origin',
        'relatedItemHost:originInfoPublisher'  => 'parent_publication-1:parent_publication_publisher',
        'relatedItemHost:partExtentPageEnd'    => 'parent_publication-1:parent_publication_page_end',
        'relatedItemHost:partExtentPageStart'  => 'parent_publication-1:parent_publication_page_start',
        'relatedItemHost:related_item_title'   => 'parent_publication-1:parent_publication_title-1:parent_publication_title_sort_portion',
        'relatedItemHost:relatedItemSeries:host_title'     => 'series-1:series_title',
        'relatedItemHost:relatedItemSeries:identifierISSN' => 'series-1:series_issn',
        'relatedItemHost:relatedItemSeries:partNumber'     => 'series-1:series_number',
        'relatedItemHost:relatedItemSeries:seriesID'       => 'series-1:series_is_columbia',

      }

      def from_acmonographpart(export_filepath, import_filepath)
        csv = HyacinthMapping::CSV.new(export_filepath, import_filepath, prefix: PREFIX)

        csv.delete_columns(%w{
          attachment tableOfContents copyright:copyrightNotice creativeCommonsLicense
          RIOXX-1:Funder RIOXX-1:Grant RIOXX-2:Funder RIOXX-2:Grant RIOXX-3:Funder
          RIOXX-3:Grant RIOXX-4:Funder RIOXX-4:Grant RIOXX-5:Funder RIOXX-5:Grant
          RIOXX:Funder RIOXX:Grant
        })

        # Merge edition columns
        csv.merge_columns('originInfoEdition-1', 'originInfoEdition')
        csv.merge_columns('relatedItemHost:originInfoEdition-1', 'relatedItemHost:originInfoEdition')

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
          csv.rename_column("#{PREFIX}:#{name[1]}:nameID", "name-#{num}:name_term.uni")
          csv.rename_column(name.string, "name-#{num}:name_term.value")

          csv.add_name_type(num: num, type: 'personal')

          delete = ['namePartGiven', 'affiliation', 'affiliation-1', 'affiliation-2', 'affiliation-3',
            'affiliationList', 'affiliation-4', 'affiliationSelect', 'affiliationSelect-1'].map{ |h| "#{name[1]}:#{h}"}
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

        # Map parent publication names
        parent_pub_names = csv.headers.map { |h| /^#{PREFIX}:(relatedItemHost:namePersonal-?(\d*)):namePartFamily$/.match(h) }.compact
        parent_pub_names.each do |name|
          csv.combine_name("#{PREFIX}:#{name[1]}:namePartGiven", "#{PREFIX}:#{name[1]}:namePartFamily")

          num = name[2].to_i + 1

          name_value  = "parent_publication-1:parent_publication_name-#{num}:parent_publication_name_term.value"
          role_header = "parent_publication-1:parent_publication_name-#{num}:parent_publication_name_role-1:parent_publication_name_role_term.value"
          name_type   = "parent_publication-1:parent_publication_name-#{num}:parent_publication_name_term.name_type"

          csv.rename_column(name.string, name_value)

          csv.rename_column("#{PREFIX}:#{name[1]}:role", role_header)
          csv.map_values_to_uri(role_header, HyacinthMapping::UriMapping::ROLES_MAP)

          csv.add_column(name_type)
          csv.table.each do |row|
            unless row[name_value].blank?
              row[name_type] = 'personal'
            end
          end

          # delete = ['namePartGiven'].map{ |h| "#{name[1]}:#{h}"}
          csv.delete_columns(["#{name[1]}:namePartGiven"])
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
                     elsif m = /^FASTGeo-?(\d*):GeoURI$/.match(no_prefix_header)
                       "subject_geographic-#{m[1].to_i + 1}:subject_geographic_term.uri"
                     elsif m = /^FASTGeo-?(\d*):Geo$/.match(no_prefix_header)
                       "subject_geographic-#{m[1].to_i + 1}:subject_geographic_term.value"
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
        csv.normalize_doi('parent_publication-1:parent_publication_doi')

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
