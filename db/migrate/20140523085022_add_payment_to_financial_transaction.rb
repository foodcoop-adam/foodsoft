class AddPaymentToFinancialTransaction < ActiveRecord::Migration
  def up
    change_column :financial_transactions, :amount, :decimal, :precision => 8, :scale => 2, :default => nil, :null => true

    add_column :financial_transactions, :updated_on, :timestamp
    add_column :financial_transactions, :payment_method, :string
    add_column :financial_transactions, :payment_plugin, :string
    add_column :financial_transactions, :payment_id, :string
    add_column :financial_transactions, :payment_amount, :decimal, :precision => 8, :scale => 3
    add_column :financial_transactions, :payment_currency, :string
    add_column :financial_transactions, :payment_state, :string
    add_column :financial_transactions, :payment_fee, :decimal, :precision => 8, :scale => 3
    add_column :financial_transactions, :payment_acct_number, :string
    add_column :financial_transactions, :payment_acct_name, :string
    add_column :financial_transactions, :payment_info, :text

    add_index :financial_transactions, [:payment_plugin, :payment_id]
  end

  def down
    remove_index :financial_transactions, [:payment_plugin, :payment_id]

    remove_column :financial_transactions, :updated_on
    remove_column :financial_transactions, :payment_method
    remove_column :financial_transactions, :payment_plugin
    remove_column :financial_transactions, :payment_id
    remove_column :financial_transactions, :payment_amount
    remove_column :financial_transactions, :payment_currency
    remove_column :financial_transactions, :payment_state
    remove_column :financial_transactions, :payment_fee
    remove_column :financial_transactions, :payment_acct_number
    remove_column :financial_transactions, :payment_acct_name
    remove_column :financial_transactions, :payment_info

    change_column :financial_transactions, :amount, :decimal, :precision => 8, :scale => 2, :default => 0, :null => false
  end
end
