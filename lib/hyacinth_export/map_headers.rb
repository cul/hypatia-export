require 'hyacinth_export/csv'
require 'hyacinth_export/mappings/ac_pub_article10'
require 'hyacinth_export/mappings/ac_etd'
require 'hyacinth_export/mappings/ac_serial_part'
require 'hyacinth_export/mappings/ac_type_book10'
require 'hyacinth_export/mappings/ac_type_book_chapter10'
require 'hyacinth_export/mappings/ac_wp10'

module HyacinthExport
  class MapHeaders
    include HyacinthExport::Mappings::AcPubArticle10
    include HyacinthExport::Mappings::AcEtd
    include HyacinthExport::Mappings::AcSerialPart
    include HyacinthExport::Mappings::AcTypeBook10
    include HyacinthExport::Mappings::AcTypeBookChapter10
    include HyacinthExport::Mappings::AcWp10
  end
end
