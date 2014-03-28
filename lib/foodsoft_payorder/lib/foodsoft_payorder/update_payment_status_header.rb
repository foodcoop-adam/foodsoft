module FoodsoftPayorder
  module UpdatePaymentStatusHeader

    module GroupOrdersController
      def self.included(base) # :nodoc:
        base.class_eval do

          # add javascript to update button - can't use deface because it's javascript
          # TODO use something like content_for_in_controllers, move js to partial
          alias_method :foodsoft_payorder_orig_price_details, :price_details
          def price_details
            foodsoft_payorder_orig_price_details
            return unless FoodsoftPayorder.enabled?
            html = view_context.order_payment_status_button class: 'price_details'
            @add_javascript ||= ''
            @add_javascript += "$('.page-header .payment-status-btn-container').html('#{view_context.j html}');"
          end

        end
      end
    end

  end
end

ActiveSupport.on_load(:after_initialize) do
  GroupOrdersController.send :include, FoodsoftPayorder::UpdatePaymentStatusHeader::GroupOrdersController
end
