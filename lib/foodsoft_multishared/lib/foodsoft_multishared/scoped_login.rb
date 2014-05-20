module FoodsoftMultishared

  # add scope checking to authenticate 
  module LoginScope
    def self.included(base) # :nodoc:
      base.class_eval do

        alias_method :foodsoft_multishared_orig_authenticate, :authenticate
        def authenticate(role = 'any')
          result = foodsoft_multishared_orig_authenticate(role)
          if current_user
            if current_user.ordergroup.present?
              # ok if ordergroup is current scope or wildcard
            elsif current_user.groups.any?
              # ok if any group is current scope or wildcard
            else
              session[:return_to] = request.original_url
              redirect_to_login :alert => "You're not a member of #{FoodsoftConfig[:name]}. Perhaps you meant to #{view_context.link_to 'login here', login_path(foodcoop: FoodsoftConfig[:default_scope])}?"
            end
          end
          result
        end

      end
    end
  end

  # allow members with a '*' group to login anywhere + more friendly wrong-foodcoop-login message
  module LoginWildcard
    def self.included(base) # :nodoc:
      base.class_eval do
        before_filter :foodsoft_multishared_find_user, only: :create

        private
        def foodsoft_multishared_find_user
          @user = User.unscoped.authenticate(params[:nick], params[:password])
          if @user and not @user.groups.any?
            redirect_to_login :alert => "You're not a member of #{FoodsoftConfig[:name]}. Perhaps you meant to #{view_context.link_to 'login here', login_path(foodcoop: FoodsoftConfig[:default_scope])}?"
          end
        end
      end
    end
  end

  # redirect to foodcoop selection page when enabled
  module SelectAfterLogin
    def self.included(base) # :nodoc:
      base.class_eval do
        before_filter :foodsoft_multishared_redir_select, only: :create

        private
        def foodsoft_multishared_redir_select
          if FoodsoftConfig[:select_scope].to_s == 'login'
            session[:return_to] = home_select_foodcoop_path
          end
        end
      end
    end
  end

  # the default scope's login page redirects a member to its own foodcoop
  module DefaultMultilogin
    def self.included(base) # :nodoc:
      base.class_eval do

        with_options if: proc { FoodsoftConfig.scope == FoodsoftConfig[:default_scope] } do |o|
          o.before_filter :foodsoft_multishared_central_login, only: :create
        end

        private

        def foodsoft_multishared_central_login
          session.clear # to avoid confusion and redirection between login forms
          user = User.unscoped.authenticate(params[:nick], params[:password])
          if user
            # any ordergroup is fine, we'll set the scope from that
            ordergroup = Ordergroup.unscoped.includes(:memberships).where(memberships: {user_id: user.id}).first
            Rails.logger.debug "Multishared central login for user##{user.id} with scope #{ordergroup.scope rescue '(none)'}"
            if ordergroup.nil?
              redirect_to_login :alert => "Please ask your foodcoop to add you to an ordergroup."
            elsif ordergroup.scope.blank?
              redirect_to_login :alert => "Your ordergroup has no foodcoop. Sorry, that's not supposed to happen, please contact us."
            elsif ordergroup.scope == '*'
              redirect_to_login :alert => "Since you are a member of all foodcoops, you need to go to a specific foodcoop's login page."
            else
              FoodsoftConfig.select_foodcoop ordergroup.scope
            end
          end
        end

      end
    end
  end

end

# now patch desired controllers to include this
ActiveSupport.on_load(:after_initialize) do
  ApplicationController.send :include, FoodsoftMultishared::LoginScope
  SessionsController.send :include, FoodsoftMultishared::DefaultMultilogin
  SessionsController.send :include, FoodsoftMultishared::LoginWildcard
  SessionsController.send :include, FoodsoftMultishared::SelectAfterLogin
end
