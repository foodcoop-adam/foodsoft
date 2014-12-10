# Set login url when access is denied to Vokomokum login.

module FoodsoftVokomokum

  module UseVokomokumLogin

    def self.included(base) # :nodoc:
      base.class_eval do

        def redirect_to_login(options={})
          redirect_to login_vokomokum_url, options
        end

        # also do single-logout
        alias_method :foodsoft_vokomokum_orig_logout, :logout
        def logout
          foodsoft_vokomokum_orig_logout
          # remove cookies to avoid logging in silently again, as if no logout happened
          cookies.delete(:Mem, domain: FoodsoftConfig[:vokomokum_cookie_domain])
          cookies.delete(:Key, domain: FoodsoftConfig[:vokomokum_cookie_domain])
        end

      end
    end
  end

end

ActiveSupport.on_load(:after_initialize) do
  ApplicationController.send :include, FoodsoftVokomokum::UseVokomokumLogin
end

