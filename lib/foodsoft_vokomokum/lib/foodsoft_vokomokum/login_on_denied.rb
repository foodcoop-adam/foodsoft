# Set login url when access is denied to Vokomokum login.

module FoodsoftVokomokum

  module UseVokomokumLogin

    def self.included(base) # :nodoc:
      base.class_eval do

        def redirect_to_login(options={})
          redirect_to login_vokomokum_url, options
        end

      end
    end
  end

end

ActiveSupport.on_load(:after_initialize) do
  ApplicationController.send :include, FoodsoftVokomokum::UseVokomokumLogin
end

