module FoodsoftVokomokum
  module GroupOrder

    def self.included(base) # :nodoc:
      base.class_eval do
        alias_method :orig_update_price!, :update_price!

        def update_price!
          ret = orig_update_price!

          if ret and order.finished?
            group_orders = ordergroup.group_orders.includes(:order)
              .where(orders: {state: 'finished'})
            amounts = {ordergroup.id => group_orders.sum(:price)}
            FoodsoftVokomokum.upload_amounts(amounts, 'Groente')
          else
            ret
          end
        end

      end
    end

  end
end

ActiveSupport.on_load(:after_initialize) do
  GroupOrder.send :include, FoodsoftVokomokum::GroupOrder
end
