module FoodsoftSignup
  class Engine < ::Rails::Engine
    def default_foodsoft_config(cfg)
      cfg[:use_approval] = 'signup'
    end
  end
end
