# TODO: make this a binary tree
class RoleLink < ActiveRecord::Base
  belongs_to :parent, :class_name => "Role", :foreign_key => :parent_id
  belongs_to :child, :class_name => "Role", :foreign_key => :child_id

  validates_uniqueness_of :child_id, :scope => :parent_id

  validate :no_self_link

  private
  def no_self_link
    errors.add_to_base("Parent and Child cannot be the same") unless parent != child
  end
  
end
