module FoodsoftMultishared
  class Engine < ::Rails::Engine
    # make sure assets we include in our engine only are precompiled too
    if defined? FoodsoftSignup
      initializer 'foodsoft_multishared.assets', :group => :all do |app|
        app.config.assets.precompile += %w(maps.js maps.css)
      end
    end
  end
end
