
class Asset < ActiveRecord::Base
  has_attachment  :storage => :file_system, 
                  :path_prefix => ASSET_LOCATION, 
                  :max_size => 2500.megabytes,
                  :thumbnails => { :icon => '40x40>', :thumb => "100x100>"}

  
  validates_as_attachment
  
  has_many :attachments, :dependent => :destroy
  
end
