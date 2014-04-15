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
            transaction do
              sum = 0
              max_sum = account_balance - value_of_finished_orders
              order_articles = []
              group_order_article_quantities.includes(:group_order_article => {:group_order => :order})
                    .merge(Order.where(state: :open)).order('created_on ASC').each do |goaq|
                goa = goaq.group_order_article
                goaq_price = goa.total_price(goa.order_article, goaq.quantity, goaq.tolerance)
                if sum + goaq_price <= max_sum
                  sum += goaq_price
                  if goaq.financial_transaction.blank?
                    goaq.financial_transaction = transaction
                    goaq.save
                    order_articles << goa.order_article
                  end
                elsif goaq.financial_transaction_id.present?
                  # TODO - do we need to reset it or not?
                  #   When an ordergroup ordered and then his account is debited, this may occur.
                  #   Some foodcoops may want to keep already paid articles, others may want to
                  #   be more strict and only deliver articles as long as the account balance
                  #   suffices.
                  #   It might be nice to introduce a configuration option for this.
                end
              end
              # need to update OrderArticle after payment as well
              order_articles.uniq.each do |order_article|
                order_article.update_results!
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

          # Don't merge quantities when one has been payed and the other not
          alias_method :foodsoft_payorder_orig_update_quantities_merge, :update_quantities_merge
          def update_quantities_merge(quantities)
            if FoodsoftPayorder.enabled?
              if quantities[0] and quantities[1]
                quantities[0].send :foodsoft_payorder_set_transaction # make sure it's set
                if quantities[0].financial_transaction.present? != quantities[1].financial_transaction.present?
                  return quantities
                end
              end
            end
            foodsoft_payorder_orig_update_quantities_merge quantities
          end

        end
      end
    end

    module GroupOrderArticleQuantity
      def self.included(base) # :nodoc:
        base.class_eval do
          belongs_to :financial_transaction

          before_create :foodsoft_payorder_set_transaction, if: proc { FoodsoftPayorder.enabled? }

          private

          # When a new GroupOrderArticleQuantity is created, check available funds and set it
          # as paid by default when it suffices. This is to make sure that articles are ordered
          # without needing to pay when account balance is enough.
          def foodsoft_payorder_set_transaction
            return if financial_transaction.present? # don't need to do this twice

            goa = group_order_article
            ordergroup = goa.group_order.ordergroup
            # the group_order_article's tolerance and quantity have been updated at this stage
            # the group_order total has not yet been updated at this stage
            funds_avail = ordergroup.get_available_funds
            funds_avail += goa.total_price(goa.order_article, goa.quantity_was, goa.tolerance_was) - goa.total_price

            if funds_avail >= 0
              self.financial_transaction = ordergroup.financial_transactions.order('created_on DESC').where('amount > 0').first
            end
          end

        end
      end
    end

    module OrderArticle
      def self.included(base) # :nodoc:
        base.class_eval do
         has_many :group_order_article_quantities, :through => :group_order_articles

          private

          # only count paid amounts
          alias_method :foodsoft_payorder_orig_collect_result, :collect_result
          def collect_result(attr)
            if not FoodsoftPayorder.enabled? or attr.to_s == 'result'
              foodsoft_payorder_orig_collect_result(attr)
            else
              group_order_article_quantities
                .where('group_order_article_quantities.financial_transaction_id IS NOT NULL')
                .collect(&attr).sum
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
  OrderArticle.send :include, FoodsoftPayorder::UpdateGroupOrderArticles::OrderArticle
end
