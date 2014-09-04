module FoodsoftOrderdoc
  class Engine < ::Rails::Engine
    def default_foodsoft_config(cfg)
      # protect filesystem path
      cfg[:protected][:shared_supplier_assets_path] = true
    end
  end
end
