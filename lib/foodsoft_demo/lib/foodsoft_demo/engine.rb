module FoodsoftDemo
  class Engine < ::Rails::Engine
    def default_foodsoft_config(cfg)
      # protected by default; set to +false+ in +app_config.yml+ to enable setting this
      cfg[:protected][:use_demo_autologin] = true
      cfg[:protected][:restrict_new_message] = true
    end
  end
end
