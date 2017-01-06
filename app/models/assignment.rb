class Assignment < ActiveRecord::Base
  belongs_to :subject, :polymorphic => :true
  belongs_to :role
  
  validates_presence_of :subject
  validates_presence_of :role
  
  validates_uniqueness_of :role_id, :scope => [:subject_id, :subject_type]
  
  def to_s
    subject.to_s
  end
  
  def users
    if subject.class == User
      Array[subject]
    else
      subject.users
    end
  end
end
