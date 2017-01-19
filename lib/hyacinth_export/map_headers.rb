require 'hyacinth_export/csv'
require 'hyacinth_export/mappings/ac_pub_article10'
require 'hyacinth_export/mappings/ac_etd'

module HyacinthExport
  class MapHeaders
    include HyacinthExport::Mappings::AcPubArticle10
    include HyacinthExport::Mappings::AcEtd
  end
end
