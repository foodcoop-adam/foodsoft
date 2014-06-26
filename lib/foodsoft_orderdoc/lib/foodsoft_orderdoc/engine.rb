module FoodsoftOrderdoc
  class Engine < ::Rails::Engine
    def foodsoft_default_config(cfg)
      # protect filesystem path
      cfg[:protected][:shared_supplier_assets_path] = true
    end
  end
end
