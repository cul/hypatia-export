class Workflow < ActiveRecord::Base
  validates_uniqueness_of :name
  validates_length_of :name, :maximum => 50
  
  has_many :permissions, :as => :permissible, :dependent => :destroy
  has_many :roles, :as => :context, :dependent => :destroy
  
  has_many :spaces

    
  def to_s
    name
  end
  
  def machine
    "Workflows::#{name}".constantize
  end
  
  def machine_from_base(base, status_method)
    machine.new(:base => base, :status_method => status_method)
  end
  
end



