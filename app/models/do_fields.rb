# This class represents records in Fedora repository
require 'deposits/sword'
class DoFields < ActiveRecord::Base
  establish_connection :adapter  => Deposits::Sword::SwordTools.getSwordConfig['fedora_db_adapter'],
                       :host     => Deposits::Sword::SwordTools.getSwordConfig['fedora_db_host'],
                       :port     => Deposits::Sword::SwordTools.getSwordConfig['fedora_db_port'],
                       :username => Deposits::Sword::SwordTools.getSwordConfig['fedora_db_user'],
                       :password => Deposits::Sword::SwordTools.getSwordConfig['fedora_db_password'],
                       :database => Deposits::Sword::SwordTools.getSwordConfig['fedora_db']
  
  self.table_name = "doFields"
  
  validates_presence_of :pid
  validates_presence_of :cDate

end