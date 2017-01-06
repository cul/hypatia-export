class Export < ActiveRecord::Base
  belongs_to :external_store
  belongs_to :item
  belongs_to :mapping

  validates_presence_of :external_store
  validates_presence_of :item
  
  has_options

  def fedora_targets
    @fedora_targets ||= begin
      targets = Hash.arbitrary_depth

      ExternalTarget.find_all_by_external_store_id(external_store_id).each do |target|
        targets[target.target_type][target.name] = target.value
      end
      targets
    end
  end
end
