module HyacinthExport
  module UriMapping
    GENRE_MAP = {
      'abstracts' => 'http://vocab.getty.edu/aat/300026032',
      'articles' => 'http://vocab.getty.edu/aat/300048715',
      'article' => 'http://vocab.getty.edu/aat/300048715',
      'blog posts' => 'http://vocab.getty.edu/aat/300026291',
      'books' => 'http://vocab.getty.edu/aat/300060417',
      'book chapters' => 'http://vocab.getty.edu/aat/300311699',
      'charts' => 'http://vocab.getty.edu/aat/300026848',
      'computer software' => 'http://vocab.getty.edu/aat/300028566',
      'conferences' => 'http://purl.org/coar/resource_type/c_c94f',
      'conference posters' => 'http://purl.org/coar/resource_type/c_c94f',
      'conference proceedings' => 'http://purl.org/coar/resource_type/c_c94f',
      'datasets' => 'http://vocab.getty.edu/aat/300312038',
      'dissertations'  => 'http://vocab.getty.edu/aat/300028028',
      'fictional works' => 'http://vocab.getty.edu/aat/300055918',
      'images' => 'http://vocab.getty.edu/aat/300054154',
      'interviews and roundtables' => 'http://vocab.getty.edu/aat/300026392',
      'journals' => 'http://vocab.getty.edu/aat/300048715',
      'letters' => 'http://vocab.getty.edu/aat/300026291',
      'master\'s theses' => 'http://vocab.getty.edu/aat/300028028',
      'moving images' => 'http://vocab.getty.edu/aat/300249172',
      'musical compositions' => 'http://id.loc.gov/vocabulary/graphicMaterials/tgm006906.html',
      'notes' => 'http://vocab.getty.edu/aat/300026291',
      'papers' => 'http://purl.org/coar/resource_type/c_c94f',
      'performances' => 'http://vocab.getty.edu/aat/300069200',
      'preprint' => 'http://vocab.getty.edu/aat/300048715',
      'presentations' => 'http://vocab.getty.edu/aat/300258677',
      'presentation' => 'http://vocab.getty.edu/aat/300258677',
      'promotional materials' => 'http://vocab.getty.edu/aat/300026096',
      'reports' => 'http://vocab.getty.edu/aat/300027267',
      'reviews' => 'http://id.loc.gov/authorities/genreForms/gf2014026168',
      'scripts' => 'http://vocab.getty.edu/aat/300055918',
      'technical reports' => 'http://vocab.getty.edu/aat/300027267',
      'technical report' => 'http://vocab.getty.edu/aat/300027267',
      'undergraduate theses' => 'http://vocab.getty.edu/aat/300028028',
      'unpublished papers' => 'http://vocab.getty.edu/aat/300027267',
      'websites' => 'http://vocab.getty.edu/aat/300027267',
      'working papers' => 'http://vocab.getty.edu/aat/300027267',
      'working paper' => 'http://vocab.getty.edu/aat/300027267'
    }

    LANGUAGE_MAP = {
      'english' => 'http://id.loc.gov/vocabulary/iso639-2/eng',
      'arabic' => 'http://id.loc.gov/vocabulary/iso639-2/ara',
      'chinese' => 'http://id.loc.gov/vocabulary/iso639-2/chi',
      'dutch' => 'http://id.loc.gov/vocabulary/iso639-2/dut',
      'french' => 'http://id.loc.gov/vocabulary/iso639-2/fre',
      'german' => 'http://id.loc.gov/vocabulary/iso639-2/ger',
      'greek' => 'http://id.loc.gov/vocabulary/iso639-2/gre',
      'hebrew' => 'http://id.loc.gov/vocabulary/iso639-2/heb',
      'italian' => 'http://id.loc.gov/vocabulary/iso639-2/ita',
      'japanese' => 'http://id.loc.gov/vocabulary/iso639-2/jpn',
      'portuguese' => 'http://id.loc.gov/vocabulary/iso639-2/por',
      'spanish' => 'http://id.loc.gov/vocabulary/iso639-2/spa',
      'turkish' => 'http://id.loc.gov/vocabulary/iso639-2/tur',
      'urdu' => 'http://id.loc.gov/vocabulary/iso639-2/urd',
      'yiddish' => 'http://id.loc.gov/vocabulary/iso639-2/yid',
    }

    ROLES_MAP = {
      'author' => 'http://id.loc.gov/vocabulary/relators/aut',
      'contributor' => 'http://id.loc.gov/vocabulary/relators/ctb',
      'director' => 'http://id.loc.gov/vocabulary/relators/drt',
      'editor' => 'http://id.loc.gov/vocabulary/relators/edt',
      'interviewee' => 'http://id.loc.gov/vocabulary/relators/ive',
      'interviewer' => 'http://id.loc.gov/vocabulary/relators/ivr',
      'moderator' => 'http://id.loc.gov/vocabulary/relators/mod',
      'producer' => 'http://id.loc.gov/vocabulary/relators/pro',
      'speaker' => 'http://id.loc.gov/vocabulary/relators/spk',
      'thesis advisor' => 'http://id.loc.gov/vocabulary/relators/ths',
      'translator' => 'http://id.loc.gov/vocabulary/relators/trl',
      'originator' => 'http://id.loc.gov/vocabulary/relators/org',
    }


    def value_to_uri(value_column, uri_column_name, map)
      # update the values in the value column to uris
      i = array.first.find_index(value_column)
      array.each_with_index do |row, index|
        next if index.zero?
        if row[i]
          value = row[i].downcase
          uri = map[value]
          if uri
            row[i] = uri
          else
            raise "could not find uri for #{value}"
          end
        end
      end
      # rename column to uri_column_name
      array.first[i] = uri_column_name
      array
    end
  end
end
