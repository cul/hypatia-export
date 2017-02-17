Dir["#{Rails.root}/lib/hyacinth_export/mappings/*.rb"].each { |file| require file }

module HyacinthExport
  class MapHeaders
    include HyacinthExport::Mappings::AcPubArticle10
    include HyacinthExport::Mappings::AcEtd
    include HyacinthExport::Mappings::AcSerialPart
    include HyacinthExport::Mappings::AcTypeBook10
    include HyacinthExport::Mappings::AcTypeBookChapter10
    include HyacinthExport::Mappings::AcWp10
    include HyacinthExport::Mappings::AcTypeAv
    include HyacinthExport::Mappings::AcTypeUnpubItem10
  end
end
