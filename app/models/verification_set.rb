class VerificationSet < ActiveRecord::Base
  has_many :tests, :class_name => "VerificationTest", :foreign_key => :set_id, :dependent => :destroy


  def run(item)
    actions = ActionArray.new()

    tests.each do |test|
      actions.results |= test.run(item)
    end
    
    return actions
  end
end
