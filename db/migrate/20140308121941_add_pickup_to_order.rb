class AddPickupToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :pickup, :datetime
  end
end
