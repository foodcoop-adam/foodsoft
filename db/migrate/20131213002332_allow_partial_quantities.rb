class AllowPartialQuantities < ActiveRecord::Migration
  def up
    indices_destroy
    change_to_decimal :group_order_article_quantities, :quantity, :default => 0
    change_to_decimal :group_order_article_quantities, :tolerance, :default => 0
    change_to_decimal :group_order_articles, :quantity, :default => 0, :null => false
    change_to_decimal :group_order_articles, :tolerance, :default => 0, :null => false
    change_to_decimal :order_articles, :quantity, :default => 0, :null => false
    change_to_decimal :order_articles, :tolerance, :default => 0, :null => false
    indices_create
  end

  def down
    indices_destroy
    change_column :group_order_article_quantities, :quantity, :integer, :default => 0
    change_column :group_order_article_quantities, :tolerance, :integer, :default => 0
    change_column :group_order_articles, :quantity, :integer, :default => 0, :null => false
    change_column :group_order_articles, :tolerance, :integer, :default => 0, :null => false
    change_column :order_articles, :quantity, :integer, :default => 0, :null => false
    change_column :order_articles, :tolerance, :integer, :default => 0, :null => false
    indices_create
  end

  def change_to_decimal(table, field, options={})
    change_column table, field, :decimal, options.merge({:precision => 8, :scale => 3})
  end

  # remove and add index to avoid sqlite error "<index> is too long; the limit is 64 characters"
  # see also http://stackoverflow.com/questions/12666727
  def indices_destroy
    remove_index :group_order_article_quantities, :group_order_article_id
    remove_index :group_order_articles, :order_article_id
    remove_index :group_order_articles, :group_order_id
  end
  def indices_create
    add_index :group_order_articles, :group_order_id
    add_index :group_order_articles, :order_article_id
    add_index :group_order_article_quantities, :group_order_article_id
  end
end
