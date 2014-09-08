module FoodsoftPayorder
  # remove unpaid member orders when the order is finished
  module CleanupOnOrderFinish

    module Order
      def self.included(base) # :nodoc:
        base.class_eval do

          alias_method :foodsoft_payorder_orig_finish!, :finish!
          def finish!(user, options={})
            if FoodsoftPayorder.enabled? :remove_unpaid and not finished?
              # remove unpaid quantities
              # @note the use of +#delete_all+ assumes that no callbacks are present for +GroupOrderArticleQuantity+
              # http://stackoverflow.com/questions/4235838/rails-is-it-possible-to-delete-all-with-inner-join-conditions
              goas = GroupOrderArticle.joins(:order_article)
                                      .where(order_articles: {order_id: self.id})
                                      .select('group_order_articles.id')
              GroupOrderArticleQuantity.where("group_order_article_id IN (#{goas.to_sql})")
                                       .where('financial_transaction_id IS NULL OR confirmed IS NULL or confirmed = ?', false)
                                       .delete_all
              # remove unpaid group_order_articles
              GroupOrderArticle.includes(:order_article, :group_order_article_quantities)
                               .where(order_articles: {order_id: self.id})
                               .group('group_order_articles.id').having('COUNT(group_order_article_quantities.id)=0')
                               .destroy_all
            end
            foodsoft_payorder_orig_finish!(user, options)
          end

        end
      end
    end
  end
end

ActiveSupport.on_load(:after_initialize) do
  Order.send :include, FoodsoftPayorder::CleanupOnOrderFinish::Order
end
