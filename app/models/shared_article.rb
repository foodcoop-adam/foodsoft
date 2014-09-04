class SharedArticle < ActiveRecord::Base

  # connect to database from sharedLists-Application
  SharedArticle.establish_connection(FoodsoftConfig[:shared_lists])
  # set correct table_name in external DB
  self.table_name = 'articles'

  belongs_to :shared_supplier, :foreign_key => :supplier_id

  after_find :set_shared_price_markup

  def build_new_article(supplier)
    supplier.articles.build(
        :name => name,
        :unit => unit,
        :note => note,
        :manufacturer => manufacturer,
        :origin => origin,
        :price => price,
        :tax => tax,
        :deposit => deposit,
        :unit_quantity => unit_quantity,
        :quantity => quantity,
        :order_number => number,
        :article_category => ArticleCategory.find_match(category),
        # convert to db-compatible-string
        :shared_updated_on => updated_on.to_formatted_s(:db)
    )
  end


  private

  # add margin on top of supplier price
  def set_shared_price_markup
    if FoodsoftConfig[:price_markup_shared]
      self.price *= ( 1 + FoodsoftConfig[:price_markup_shared]/100 )
    end
  end

end
