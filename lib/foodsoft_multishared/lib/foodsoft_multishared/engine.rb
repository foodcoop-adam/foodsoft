module FoodsoftMultishared
  class Engine < ::Rails::Engine
    # make sure assets we include in our engine only are precompiled too
    if defined? FoodsoftSignup
      initializer 'foodsoft_multishared.assets', :group => :all do |app|
        app.config.assets.precompile += %w(maps.js maps.css)
      end
    end

    # remove confg menu item in multishared
    def navigation(primary, context)
      return if primary[:config].nil?
      sub_nav = primary[:config].sub_navigation
      if i = sub_nav.items.index(sub_nav[:config])
        primary[:config].sub_navigation.items.delete_at(i)
      end
    end
  end
end
