class SwordDeposit < ActiveRecord::Base
    
  validates_presence_of :user
  validates_presence_of :file_name
  validates_presence_of :content_type
  validates_presence_of :packaging
  validates_presence_of :collection
  validates_presence_of :md5_digest
  validates_presence_of :received
  belongs_to :item
  def zip_storage_path(dir=nil)
    File.join(*([dir,md5_digest[0,2],"#{md5_digest}.zip"].compact))
  end
end