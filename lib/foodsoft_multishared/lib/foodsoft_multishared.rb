require 'deface'
require 'foodsoft_multishared/engine'
require 'foodsoft_multishared/scoped_login'
require 'foodsoft_multishared/scoped_signup'
require 'foodsoft_multishared/use_foodcoop_scope'
require 'foodsoft_multishared/fix_foodcoop_group_uniqueness'
require 'foodsoft_multishared/default_sub_name'
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

  # returns whether the current scope has access to all scopes
  def self.is_master?
    master_scope = FoodsoftConfig[:master_scope]
    master_scope and FoodsoftConfig.scope == master_scope
  end

  # returns which foodcoop scopes one can view
  def self.view_scopes(type=nil)
    scopes = [FoodsoftConfig.scope, '*']
    if [Supplier, ArticleCategory, Order].include? type
      join_scopes = FoodsoftConfig[:join_scope] || []
      join_scopes.is_a? Hash and join_scopes = join_scopes.keys
      join_scopes.is_a? Array or join_scopes = [join_scopes]
      scopes + join_scopes
    else
      scopes
    end
  end

  # returns list of foodcoops
  def self.get_scopes(hidden=false)
    scopes = FoodsoftConfig.send :scopes
    app_config = FoodsoftConfig.class_eval 'APP_CONFIG'
    hidden ? scopes : scopes.reject {|scope| app_config[scope]['hidden']}
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

  # return address line for contact info
  def self.address_line(contact)
    contact = contact.stringify_keys
    %w(street zip_code city).map{|p| contact[p]}.compact.join(', ')
  end
end
