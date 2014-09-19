module FoodsoftMultishared

  # Monkey-patch to Completely disable settings in the database
  module DisableSettingConfig
    def self.included(base) # :nodoc:
      base.class_eval do

        def self.[](key)
          value = config[key.to_sym]
          value = default_config[key.to_sym] if value.nil?
          fix_hash value
        end

        def self.[]=(key, value)
          return false
        end

      end
    end
  end

  # Monkey-patch configuration controller to disable it
  module DisableConfigsController
    def self.included(base) # :nodoc:
      base.class_eval do
        before_filter except: :list do
          redirect_to root_path, alert: I18n.t('application.controller.error_plugin_disabled')
        end
      end
    end
  end

end

ActiveSupport.on_load(:after_initialize) do
  FoodsoftConfig.send :include, FoodsoftMultishared::DisableSettingConfig
  Admin::ConfigsController.send :include, FoodsoftMultishared::DisableConfigsController
end
