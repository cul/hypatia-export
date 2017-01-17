module HyacinthExport
  module Fields

    # Map with fields from Hypatia to Hyacinth. Organized by template name prefix.
    MAP = {
      'acPubArticle10' => {
        'abstract'                   => 'abstract-1:abstract_value',
        'typeResc'                   => 'type_of_resource-1:type_of_resource_value',
        'originDateIssued'           => 'date_issued-1:date_issued_start_value',
        'noteField'                  => 'note-1:note_value',
        'genreGenre'                 => 'genre-1:genre_term.value',
        'langLanguageTermText'       => 'language-1:language_term.value',
        'identifierHDL'              => 'cnri_handle_identifier-1:cnri_handle_identifier_value',
        'tiInfoTitle'                => 'title-1:title_sort_portion',
        'identifierDOI'              => 'doi_identifier-1:doi_identifier_value',
        'identifier:iDIdentifierHandle' => 'cnri_handle_identifier-1:cnri_handle_identifier_value',
        'copyEmbargo:copyEmDateEnd'  => 'embargo_release_date-1:embargo_release_date_value',
        'relatedArticleHost:iDIdentifierISSN' => 'parent_publication-1:parent_publication_issn',
        'relatedArticleHost:partDateYear'     => 'parent_publication-1:parent_publication_date_created_textual',
        'relatedArticleHost:partExtentEnd'    => 'parent_publication-1:parent_publication_page_end',
        'relatedArticleHost:partExtentStart'  => 'parent_publication-1:parent_publication_page_start',
        'relatedArticleHost:partIssue'        => 'parent_publication-1:parent_publication_issue',
        'relatedArticleHost:partVolume'       => 'parent_publication-1:parent_publication_volume',
        'relatedArticleHost:tiInfoTitle'      => 'parent_publication-1:parent_publication_title-1:parent_publication_title_sort_portion',
        'nameTypeCorporate:namePart'     => 'name-1:name_term.value',
        'nameTypeCorporate:nameRoleTerm' => 'name-1:name_role-1:name_role_term.value'

      },
      'acETD' => {
        'degreeInfo:degreeGrantor' => 'degree-1:degree_grantor',
        'degreeInfo:degreeName' => 'degree-1:degree_name',
        'genre'                 => 'genre-1:genre_term.value',
        'identifierHDL'         => 'cnri_handle_identifier-1:cnri_handle_identifier_value',
        'identifierISBN'        => 'isbn-1:isbn_value',
        'language'              => 'language-1:language_term.value',
        'note'                  => 'note-1:note_value',
        'originInfoDateIssued'  => 'date_issued-1:date_issued_start_value',
        'originInfoPlace'       => 'place_of_origin-1:place_of_origin_value',
        'originInfoPublisher'   => 'publisher-1:publisher_value',
        'title'                 => 'title-1:title_sort_portion',
        'typeOfResource'        => 'type_of_resource-1:type_of_resource_value'
      }
    }
  end
end
