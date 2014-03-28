# This migration comes from foodsoft_payorder_engine (originally 20140326135219)
class AddFinancialTransactionToGoaq < ActiveRecord::Migration
  def change
    add_column :group_order_article_quantities, :financial_transaction_id, :integer
  end
end
