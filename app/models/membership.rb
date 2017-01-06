class Membership < ActiveRecord::Base
  belongs_to :user
  belongs_to :group
  
  validates_presence_of :user
  validates_presence_of :group
  
  def to_s
    "#{user.to_s} -> #{group.to_s}"
  end
end
