
module FoodsoftSplitManufacturer
  module AddManufacturerToPdfControllers
    def self.included(base) # :nodoc:
      base.class_eval do

        before_filter :foodsoft_split_manufacturer_set_options, only: [:show, :foodcoop_doc], if: -> { FoodsoftSplitManufacturer.enabled? }

        private
        def foodsoft_split_manufacturer_set_options
          @doc_options ||= {}
          @doc_options[:manufacturer] = params[:manufacturer] if params[:manufacturer].present?
        end

      end
    end
  end
end

ActiveSupport.on_load(:after_initialize) do
  OrdersController.send :include, FoodsoftSplitManufacturer::AddManufacturerToPdfControllers
  if defined? FoodsoftCurrentOrders
    CurrentOrders::OrdersController.send :include, FoodsoftSplitManufacturer::AddManufacturerToPdfControllers
  end
  if defined? FoodsoftMultishared
    MultisharedOrdersController.send :include, FoodsoftSplitManufacturer::AddManufacturerToPdfControllers
  end
end
