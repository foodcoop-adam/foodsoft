if defined? FoodsoftSignup
  module FoodsoftMultishared

    # replace the default scope's signup page with one where a group can be chosen
    module MultiScopeSignup
      def self.included(base) # :nodoc:
        base.class_eval do

          # so that the default scope can have a default for all other foodcoops
          skip_before_filter :signup_limit_reached, if: -> { FoodsoftConfig.scope == FoodsoftConfig[:default_scope] }

          alias_method :foodsoft_multishared_orig_signup, :signup
          def signup
            if FoodsoftConfig.scope != FoodsoftConfig[:default_scope]
              foodsoft_multishared_orig_signup
            elsif params[:signup]
              redirect_to signup_path(foodcoop: params[:signup][:scope])
            else
              @scopes, @scopes_en, @scopes_di = MultisharedSignupController.get_scopes
              render 'multishared_signup/index'
            end
          end

        end
      end
    end

  end

  # now patch desired controllers to include this
  ActiveSupport.on_load(:after_initialize) do
    SignupController.send :include, FoodsoftMultishared::MultiScopeSignup
  end
end
