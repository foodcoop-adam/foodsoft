class AddPricesToGroupOrders < ActiveRecord::Migration
  def up
    add_column :group_orders, :net_price, :decimal, precision: 8, scale: 2
    add_column :group_orders, :gross_price, :decimal, precision: 8, scale: 2
    add_column :group_orders, :deposit, :decimal, precision: 8, scale: 2

    # we created these columns without a default to keep existing records nil
    # new records are always recomputed, so we can have a default value here
    GroupOrder.reset_column_information
    change_column_default :group_orders, :net_price, 0
    change_column_default :group_orders, :gross_price, 0
    change_column_default :group_orders, :deposit, 0

    # compute new columns for group orders
    # this can be quite expensive, so only do it for those that are really needed
    say_with_time 'update price details for open group orders' do
      GroupOrder.includes(:order).where(orders: {state: 'open'}).all.map(&:update_price!).count
    end

    say "NOTE: To show price details for previous orders, run in the rails console:"
    say "  GroupOrder.all.map(&:update_price!)"
  end

  def down
    remove_column :group_orders, :net_price
    remove_column :group_orders, :gross_price
    remove_column :group_orders, :deposit
  end
end
