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

        'identifier:IDidentifierDOI' => 'doi_identifier-1:doi_identifier_value',
        'copyEmbargo:copyEmDateEnd'  => 'embargo_release_date-1:embargo_release_date_value',

        'relatedArticleHost:iDIdentifierISSN' => 'parent_publication-1:parent_publication_issn',
        'relatedArticleHost:partDateYear'     => 'parent_publication-1:parent_publication_date_created_textual',
        'relatedArticleHost:partExtentEnd'    => 'parent_publication-1:parent_publication_page_end',
        'relatedArticleHost:partExtentStart'  => 'parent_publication-1:parent_publication_page_start',
        'relatedArticleHost:partIssue'        => 'parent_publication-1:parent_publication_issue',
        'relatedArticleHost:partVolume'       => 'parent_publication-1:parent_publication_volume',
        'relatedArticleHost:tiInfoTitle'      => 'parent_publication-1:parent_publication_title-1:parent_publication_title_sort_portion',
      }
    }
  end
end
