class Group < ActiveRecord::Base
  validates_presence_of :name
  validates_length_of :name, :maximum => 50
  
  has_many :users, :through => :memberships
  has_many :memberships, :dependent => :destroy

  has_many :roles, :through => :assignments
  has_many :assignments, :as => :subject, :dependent => :destroy

  def to_s
    name
  end

end
