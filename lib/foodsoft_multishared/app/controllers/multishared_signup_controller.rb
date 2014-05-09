class MultisharedSignupController < ApplicationController

  before_filter :require_select_enabled

  # please note that signup is currently handled in lib/foodsoft_multishared/scoped_signup.rb

  def select_foodcoop
    if request.post? and new_scope = (params[:select_foodcoop][:scope] rescue nil)
      new_config = FoodsoftMultishared.get_scope_config(new_scope)
      case new_scope
      when FoodsoftConfig[:default_scope].to_s
      when FoodsoftConfig[:master_scope].to_s
      when !FoodsoftMultishared.get_scopes.include?(new_scope)
      when new_config[:hidden]
      when FoodsoftMultishared.signup_limit_reached?(new_scope, new_config)
        redirect_to select_foodcoop_path, alert: I18n.t('foodsoft_multishared.error_scope_denied')
      else
        current_user.ordergroup.update_attribute :scope, new_scope
        redirect_to root_path(foodcoop: new_scope), notice: I18n.t('foodsoft_multishared.select_foodcoop.notice', from: FoodsoftConfig.scope, to: new_scope)
      end
    else
      @scopes, @scopes_en, @scopes_di = self.class.get_scopes
    end
  end


  # public 'helper' method
  def self.get_scopes
    scopes = FoodsoftMultishared.get_scopes.reject {|s| s==FoodsoftConfig[:default_scope]}
    scopes = Hash[scopes.map{|s| [s, FoodsoftMultishared.get_scope_config(s)]}]
    scopes_en = scopes.reject {|s,cfg| FoodsoftMultishared.signup_limit_reached?(s, cfg)}
    scopes_di = scopes.select {|s,cfg| FoodsoftMultishared.signup_limit_reached?(s, cfg)}
    [scopes, scopes_en, scopes_di]
  end

  private

  def require_select_enabled
    unless FoodsoftConfig[:select_scope]
      redirect_to root_path, alert: I18n.t('application.controller.error_plugin_disabled')
    end
  end

end
