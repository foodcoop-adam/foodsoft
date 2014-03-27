class AllowInviteWithoutGroup < ActiveRecord::Migration
  def self.up
    change_column :invites, :group_id, :integer, default: nil, null: true
  end

  def self.down
    change_column :invites, :group_id, :integer, default: 0, null: false
  end
end
