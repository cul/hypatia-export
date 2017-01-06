class Mapping < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name

  has_many :item_types, :through => :mapping_item_types
  has_many :mapping_item_types, :dependent => :destroy
  has_many :instructions, :class_name => "MappingInstruction", :order => "position"
  
  
  
  def to_s
    name
  end


  
  def build_mapper(*args)
    options = args.extract_options!
    
    check_item_integrity(options)

    Mapper.new(:mapping => self, :items => options)
  end
  
  def check_item_integrity(items)

    mapping_item_types.each do |mit|
      matches = [*items[mit.code]].compact
      raise "Object passed to mapper which is not item." if matches.detect { |m| !m.kind_of?(Item) }

      items[mit.code] = matches
      
      num_matches = matches.length
      raise "#{num_matches} #{mit.code} found, expected between #{mit.minimum} and #{mit.maximum.nil? ? 'infinity' : mit.maximum}" if num_matches < mit.minimum || (!mit.maximum.nil? && mit.maximum < num_matches) 
    end
  end

  def auto_map_items(*items)
    item_hash = {}
    mapping_item_types(true).each do |mit|
      next unless mit
      mit_items = []
      (0...mit.minimum).each do |i|
        item = items.detect { |j| j.item_type == mit.item_type }
        if item
          mit_items << items.delete_at(items.index(item))
        else
          return nil
        end
      end

      item_hash[mit.code] = mit_items
    end

    # TODO: add extras automatically
    return item_hash
  end

  
end
