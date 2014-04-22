require 'foodsoft_multishared/engine'
require 'foodsoft_multishared/scoped_login'
require 'foodsoft_multishared/scoped_signup'
require 'foodsoft_multishared/use_foodcoop_scope'
if defined? FoodsoftSignup
  require 'underscore-rails'
  require 'gmaps4rails'
  require 'markerclustererplus-rails'
  require 'jquery-scrollto-rails'
end

module FoodsoftMultishared
  # The choice for using this plugin is done by the system admistrator or integrator,
  # not by the foodcoop. It would make no sense to enable or disable this at runtime,
  # that's why there is no `enabled?` method here; loaded = active.

  # returns whether the given scope matches the current one
  def self.own_scope?(scope)
    scope.to_s == FoodsoftConfig.scope.to_s
  end

  # returns which foodcoop scopes one can view
  def self.view_scopes
    [FoodsoftConfig.scope, '*']
  end

  # returns list of foodcoops
  def self.get_scopes
    scopes = FoodsoftConfig.send :scopes
    app_config = FoodsoftConfig.class_eval 'APP_CONFIG'
    scopes.reject {|scope| app_config[scope]['hidden']}
  end

  # returns configuration for foodcoop
  def self.get_scope_config(scope)
    app_config = FoodsoftConfig.class_eval 'APP_CONFIG'
    app_config[scope.to_s].symbolize_keys
  end

  # returns whether the ordergroup signup limit has been reached or not for a scope
  def self.signup_limit_reached?(scope, limit)
    return unless defined? FoodsoftSignup
    return unless limit
    limit = limit[:signup_ordergroup_limit] if limit.respond_to? '[]'
    scope = scope.to_sym
    groups = Ordergroup.unscoped.where(scope: scope)
    groups = groups.where(approved: true) if FoodsoftSignup.enabled?(:approval)
    groups.count >= limit.to_i
  end
end