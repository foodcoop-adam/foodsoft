module FoodsoftVokomokum
  module SettleOrder

    def self.included(base) # :nodoc:
      base.class_eval do

        private

        def charge_group_orders!(user)
          charges = []
          group_orders.includes(:ordergroup => :users).find_each do |group_order|
            user_id = FoodsoftVokomokum.userid_for_ordergroup(group_order.ordergroup)
            user_id.present? or raise Exception.new("No user for ordergroup '#{group_order.ordergroup.name}'")
            charges << {order_id: id, amount: group_order.price.to_f, user_id: user_id, note: transaction_note}
          end
          s = FoodsoftVokomokum.charge_members!(user.vokomokum_auth_cookies, charges)
          Rails.logger.info s
        end

      end
    end

  end
end

ActiveSupport.on_load(:after_initialize) do
  Order.send :include, FoodsoftVokomokum::SettleOrder
end
