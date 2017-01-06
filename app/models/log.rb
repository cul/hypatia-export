class Log < ActiveRecord::Base
  belongs_to :loggable, :polymorphic => true
  validates_presence_of :loggable_id
  validates_presence_of :loggable_type
  
  belongs_to :user
  
  validates_presence_of :classification
  validates_length_of :level, :maximum => 20, :allow_nil => true
end
