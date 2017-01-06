class SwordArtifact < ActiveRecord::Base
  self.table_name = 'swords'
  validates_presence_of :depositor
  validates_presence_of :sword_pid
  validates_presence_of :received

end
