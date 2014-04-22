module FoodsoftMultishared

  # set default subname to address portion
  module DefaultSubName
    def self.included(base) # :nodoc:
      base.class_eval do
        class << self; alias_method :foodsoft_multishared_orig_select_foodcoop, :select_foodcoop end
        def self.select_foodcoop(foodcoop)
          r = foodsoft_multishared_orig_select_foodcoop(foodcoop)
          if config[:use_subname_address] and scope != config[:default_scope]
            config[:sub_name] ||=  FoodsoftMultishared.address_line(config[:contact])
          end
          r
        end
      end
    end
  end

end

ActiveSupport.on_load(:after_initialize) do
  FoodsoftConfig.send :include, FoodsoftMultishared::DefaultSubName
end
