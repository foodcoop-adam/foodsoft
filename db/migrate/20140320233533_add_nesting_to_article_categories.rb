class AddNestingToArticleCategories < ActiveRecord::Migration
  def up
    add_column :article_categories, :ancestry, :string
    add_column :article_categories, :position, :integer
    add_index :article_categories, :ancestry
    add_index :article_categories, :position
    # Use id as position so that there is an initial sort order
    ArticleCategory.update_all('position=id')
  end

  def down
    remove_index :article_categories, :position
    remove_index :article_categories, :ancestry
    remove_column :article_categories, :position
    remove_column :article_categories, :ancestry
  end
end
