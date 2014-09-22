class RemoveStaleMemberships < ActiveRecord::Migration
  def up
    Membership.where("group_id NOT IN (?)", Group.pluck(:id)).delete_all
  end
end
