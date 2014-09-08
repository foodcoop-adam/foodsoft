class AddConfirmedToGoaq < ActiveRecord::Migration
  def up
    add_column :group_order_article_quantities, :confirmed, :boolean, default: false
    # set articles in open orders to confirmed not to break existing orders
    GroupOrderArticleQuantity.joins(group_order_article: {order_article: :order})
      .where(orders: {state: 'open'})
      .update_all(confirmed: true)
  end

  def down
    remove_column :group_order_article_quantities, :confirmed
  end
end
