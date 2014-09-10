module FoodsoftMultishared

  # Restricts which configuration items can be changed by joined foodcoops.
  module RestrictScopedConfig
    def self.included(base) # :nodoc:
      base.class_eval do

        alias_method :[], :foodsoft_multishared_orig_get
        def [](key)
          if FoodsoftConfig[:join_scope] and master = FoodsoftConfig[:master_scope]
            select_scope master
            value = FoodsoftConfig[key]

          else
            foodsoft_multishared_orig_get(key)
          end
        end

        alias_method :set_missing, :foodsoft_multishared_orig_set_missing
        def set_missing
          config = foodsoft_multishared_orig_set_missing
          if FoodsoftConfig[:join_scope] and master = FoodsoftConfig[:master_scope]
            config[:protected][:all] = true
            allowed_joined_config_keys.each do |k|
              config[:protected][k] = false
              # set so that they're shown as default in the configuration screen
              config[k] = get(k, FoodsoftConfig[:master_scope])
            end
          end
          config
        end
      end
    end

    # Return config keys that foodcoops using +join_scope+ may set.
    def self.allowed_joined_config_keys
      [
        :contact, :sub_name, :home_notice,
        :pdf_font_size, :pdf_page_size, :pdf_add_page_breaks,
        :signup_ordergroup_limit
      ]
    end

  end
end

# now patch desired controllers to include this
ActiveSupport.on_load(:after_initialize) do
  FoodsoftConfig.send :include, FoodsoftMultishared::RestrictScopedConfig
end
