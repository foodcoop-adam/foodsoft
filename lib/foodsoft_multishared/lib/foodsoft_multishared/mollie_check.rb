# make Mollie check work with multishared
if defined? FoodsoftMollie
  # Mention scope with ordergroups in PDFs
  module FoodsoftMultishared
    module AddScopeToPayments

      module Mollie
        def self.included(base) # :nodoc:
          base.class_eval do
            before_filter :foodsoft_multishared_check_set_scope, only: [:check]

            private
            def foodsoft_multishared_check_set_scope
              # take care, when Mollie changes, this might need to be updated too
              transaction = FinancialTransaction.unscoped.find_by_payment_plugin_and_payment_id('mollie', params[:id])
              if transaction
                scope = Ordergroup.unscoped.find(transaction.ordergroup_id).scope
                FoodsoftConfig.select_foodcoop scope
              end
            end

          end
        end
      end

    end
  end

  ActiveSupport.on_load(:after_initialize) do
    Payments::MollieIdealController.send :include, FoodsoftMultishared::AddScopeToPayments::Mollie
  end
end
