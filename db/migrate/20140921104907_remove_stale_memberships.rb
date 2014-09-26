class RemoveStaleMemberships < ActiveRecord::Migration
  def up
    # disable since this may delete most groups in multishared(!)
    #Membership.where("group_id NOT IN (?)", Group.pluck(:id)).delete_all
  end
end
