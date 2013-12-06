class AddDivideToArticle < ActiveRecord::Migration
  def change
    add_column :articles, :unit_divide, :string
  end
end
