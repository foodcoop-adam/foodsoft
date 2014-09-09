
module FoodsoftSplitManufacturer
  module AddFilterToArticles
    def self.included(base) # :nodoc:
      base.class_eval do

        alias_method :foodsoft_split_manufacturer_order_articles, :order_articles

        def order_articles
          if FoodsoftSplitManufacturer.enabled? and not @order_articles and @options[:manufacturer]
            foodsoft_split_manufacturer_order_articles
            @order_articles = @order_articles.includes(:article).where(articles: {manufacturer: @options[:manufacturer]})
          else
            foodsoft_split_manufacturer_order_articles
          end
        end

      end
    end
  end
end

ActiveSupport.on_load(:after_initialize) do
  OrderByArticles.send :include, FoodsoftSplitManufacturer::AddFilterToArticles
  if defined? FoodsoftCurrentOrders
    MultipleOrdersByArticles.send :include, FoodsoftSplitManufacturer::AddFilterToArticles
  end
  if defined? FoodsoftMultishared
    MultipleOrdersScopeByArticles.send :include, FoodsoftSplitManufacturer::AddFilterToArticles
  end
end
