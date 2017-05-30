Dir["#{Rails.root}/lib/hyacinth_mapping/template_mapping/*.rb"].each { |file| require file }

module HyacinthMapping
  include TemplateMapping::AcPubArticle10
  include TemplateMapping::AcEtd
  include TemplateMapping::AcSerialPart
  include TemplateMapping::AcTypeBook10
  include TemplateMapping::AcTypeBookChapter10
  include TemplateMapping::AcWp10
  include TemplateMapping::AcTypeAv
  include TemplateMapping::AcTypeUnpubItem10
  include TemplateMapping::AcTypeBookChapter
  include TemplateMapping::AcDissertation
  include TemplateMapping::AcTypeBook
  include TemplateMapping::AcPubArticle
  include TemplateMapping::AcWp
  include TemplateMapping::AcTypeUnpubItem
  include TemplateMapping::AcMonograph
  include TemplateMapping::AcMonographPart
  include TemplateMapping::AcWebpagePart
end
