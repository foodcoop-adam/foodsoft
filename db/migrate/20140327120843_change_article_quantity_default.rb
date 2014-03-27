class ChangeArticleQuantityDefault < ActiveRecord::Migration
  def up
    change_column_default :articles, :quantity, nil

    # we want quantity to be nil by default, because now zero does something
    say_with_time 'Update article quantity default' do
      Article.not_in_stock.update_all quantity: nil
    end
  end

  def down
    change_column_default :articles, :quantity, 0

    # go back to default value
    say_with_time 'Update article quantity default' do
      Article.not_in_stock.update_all quantity: 0
    end
  end
end
