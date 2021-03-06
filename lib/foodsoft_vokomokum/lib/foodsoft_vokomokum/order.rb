module FoodsoftVokomokum
  module FinishOrder

    def self.included(base) # :nodoc:
      base.class_eval do
        alias_method :orig_finish!, :finish!

        attr_reader :vokomokum_finishing
        @vokomokum_finishing = false

        def finish!(user, options={})
          Order.transaction do
            @vokomokum_finishing = true
            ret = orig_finish!(user, options)
            @vokomokum_finishing = false
            FoodsoftVokomokum.upload_amounts
            ret
          end
        end

      end
    end

  end
end

ActiveSupport.on_load(:after_initialize) do
  Order.send :include, FoodsoftVokomokum::FinishOrder
end
