class MappingTemplate < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name

  def value
    filename = "private/templates/#{self.id}.xml"
    if File.exists?(filename)
      File.read(filename)
    else
      self.attributes["value"]
    end
  end
end
