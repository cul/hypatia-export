require 'hyacinth_export/uri_mapping'

module HyacinthExport::Mappings
  module AcTypeBook10
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      PREFIX = 'acTypeBook10'
      MAP = {
        'abstract'             => 'abstract_value',
        'genreGenre'           => 'genre-1:genre_term.value',
        'iDIdentifierHandle'   => 'cnri_handle_identifier-1:cnri_handle_identifier_value',
        'iDIdentifierISBN'     => 'isbn-1:isbn_value',
        'langLanguageTermText' => 'language-1:language_term.value',
      }

      def from_actypebook10(filename)
        csv = HyacinthExport::CSV.new(filename, prefix: PREFIX)

        csv.delete_columns(%w{
          Attachments classJEL classLC copyEmbargo:copyEmAccessLevel copyEmbargo:copyEmDateBegin
          copyEmbargo:copyEmIssuedBy copyEmbargo:copyEmNote copyright:accCCStatements
          copyright:copyCopyStatement extAuthorRightsStatement locURL noteRef
          originEdition physDsExtentFileSize physDsInternetMediaType recInfRecordOrigin
          relatedItemSeries:nameTitleGroup relatedItemSeries:relatedItemID subjectGeoCode
          tableOfContents
        })

        csv.headers.each do |header|
          no_prefix_header = header.gsub("#{PREFIX}:", '')

          if MAP[no_prefix_header] # mapping one-to-one fields
            csv.rename_column(header, MAP[no_prefix_header])
          end
        end

        # Map role terms from values to uris
        csv.value_to_uri('genre-1:genre_term.value', 'genre-1:genre_term.uri', HyacinthExport::UriMapping::GENRE_MAP)
        csv.value_to_uri('language-1:language_term.value', 'language-1:language_term.uri', HyacinthExport::UriMapping::LANGUAGE_MAP)

        csv.export_to_file
      end
    end
  end
end
