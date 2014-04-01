module FoodsoftPayorder
  module UpdateGroupOrderArticles

    module Ordergroup
      def self.included(base) # :nodoc:
        base.class_eval do
          has_many :group_order_article_quantities, :through => :group_order_articles

          # Recompute which articles have been paid.
          # Go through all GroupOrderArticles of open/finished orders of this ordergroup,
          # and associate them with the financial transaction, as far as the account balance
          # suffices.
          def update_group_order_articles(transaction = financial_transactions.where('amount > 0').last)
            FoodsoftPayorder.enabled? or return
            # TODO implement tolerance_is_costly for this
            transaction do
              sum = 0
              max_sum = account_balance - value_of_finished_orders
              group_order_article_quantities.includes(:group_order_article => {:group_order => :order})
                    .merge(Order.where(state: :open)).order(created_on: :desc).each do |goaq|
                goaq_price = goaq.quantity * goaq.group_order_article.order_article.price.fc_price
                if sum + goaq_price <= max_sum
                  sum += goaq_price
                  goaq.financial_transaction ||= transaction
                  goaq.save
                elsif goaq.financial_transaction_id.present?
                  # TODO - do we need to reset it or not?
                  #   When an ordergroup ordered and then his account is debited, this may occur. 
                  #   Some foodcoops may want to keep already paid articles, others may want to
                  #   be more strict and only deliver articles as long as the account balance
                  #   suffices.
                  #   It might be nice to introduce a configuration option for this.
                end
              end
            end
          end

          # always recompute after a financial transaction
          alias_method :foodsoft_payorder_orig_add_financial_transaction!, :add_financial_transaction!
          def add_financial_transaction!(amount, note, user)
            result = self.foodsoft_payorder_orig_add_financial_transaction!(amount, note, user)
            self.update_group_order_articles(financial_transactions.last)
            result
          end

        end
      end
    end

    module GroupOrderArticle
      def self.included(base) # :nodoc:
        base.class_eval do

          # When the order is finished, we only may want to include those quantities that were payed.
          # The order state is set before calculating the final result, so we check for that to see
          # if only payed quantities need to be taken into account.
          alias_method :foodsoft_payorder_orig_get_quantities_for_order_article, :get_quantities_for_order_article
          def get_quantities_for_order_article
            result = foodsoft_payorder_orig_get_quantities_for_order_article
            FoodsoftPayorder.enabled? or return result
            order_article.order.finished? or return result
            result.where('group_order_article_quantities.financial_transaction_id IS NOT NULL') 
          end

        end
      end
    end

    module GroupOrderArticleQuantity
      def self.included(base) # :nodoc:
        base.class_eval do

          # When a new GroupOrderArticleQuantity is created, check available funds and set it
          # as paid by default when it suffices. This is to make sure that articles are ordered
          # without needing to pay when account balance is enough.
          before_create :foodsoft_payorder_set_transaction, if: proc { FoodsoftPayorder.enabled? }
          def foodsoft_payorder_set_transaction
            ordergroup = group_order_article.group_order.ordergroup
            # TODO support tolerance_is_costly
            # TODO refactor common code with update_group_order_articles
            price_sum = quantity * group_order_article.order_article.price.fc_price
            if ordergroup.get_available_funds >= price_sum
              self.financial_transaction_id = ordergroup.financial_transactions.where('amount > 0').last.id
            end
          end

        end
      end
    end

  end
end

ActiveSupport.on_load(:after_initialize) do
  Ordergroup.send :include, FoodsoftPayorder::UpdateGroupOrderArticles::Ordergroup
  GroupOrderArticle.send :include, FoodsoftPayorder::UpdateGroupOrderArticles::GroupOrderArticle
  GroupOrderArticleQuantity.send :include, FoodsoftPayorder::UpdateGroupOrderArticles::GroupOrderArticleQuantity
end
