module FoodsoftDemo
  module AutoLoginDefault
    def self.included(base) # :nodoc:
      base.class_eval do

        alias_method :foodsoft_demo_orig_redirect_to_login, :redirect_to_login
        def redirect_to_login(options={})
          if FoodsoftDemo.enabled? :autologin
            redirect_to login_demo_url, options
          else
            foodsoft_demo_orig_redirect_to_login options
          end
        end

      end
    end
  end
end

ActiveSupport.on_load(:after_initialize) do
  ApplicationController.send :include, FoodsoftDemo::AutoLoginDefault
end
