module FoodsoftVokomokum
  # To charge members in the Vokomokum members system, the authentication cookies
  # are needed when settling an order. This happens in the Order model, where
  # request variables like cookies aren't availble. That's why a variable is set on
  # the currently logged-in user, which is subsequently used in the model.
  module AuthCookies

    module Set
      extend ActiveSupport::Concern

      included do
        before_filter :set_vokomokum_auth_cookies
      end

      private

      def set_vokomokum_auth_cookies
        @current_user.vokomokum_auth_cookies = session[:vokomokum_auth_cookies]
      end
    end

    module User
      extend ActiveSupport::Concern

      included do
        attr_accessor :vokomokum_auth_cookies
        # for hooks that happen in a model and return a message
        attr_accessor :vokomokum_remote_msg
      end
    end

  end
end

ActiveSupport.on_load(:after_initialize) do
  User.send :include, FoodsoftVokomokum::AuthCookies::User
  Finance::BaseController.send :include, FoodsoftVokomokum::AuthCookies::Set
end
