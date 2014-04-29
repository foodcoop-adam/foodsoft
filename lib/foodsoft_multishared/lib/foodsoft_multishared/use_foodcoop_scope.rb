module FoodsoftMultishared

  # cannot change scope
  # TODO introduce something like a superadmin who can
  module ProtectScope
    def self.included(base) # :nodoc:
      base.class_eval do
        validate :foodsoft_multishared_protect_scope, unless: -> { FoodsoftMultishared.is_master? }

        private
        def foodsoft_multishared_protect_scope
          if not new_record? and not FoodsoftMultishared.own_scope?(scope_was)
            Rails.logger.debug "Attempt to edit record from different scope #{scope_was} (mine is #{FoodsoftConfig.scope})"
            # can only edit records that match our scope
            errors[:base] << "This #{self.class.model_name.human} is not owned by your foodcoop."
          elsif not FoodsoftMultishared.own_scope?(scope)
            # cannot change scope to something else
            Rails.logger.debug "Attempt to change scope from #{scope_was} to #{scope}"
            errors.add :scope, "Scope must be #{FoodsoftConfig.scope}."
          end
        end
      end
    end
  end

  # only show records with matching scope (except for master instance)
  module RestrictScope
    def self.included(base) # :nodoc:
      base.class_eval do
        default_scope -> { where(scope: FoodsoftMultishared.view_scopes) unless FoodsoftMultishared.is_master? }
      end
    end
  end

  module RestrictScopeAlways
    def self.included(base) # :nodoc:
      base.class_eval do
        default_scope -> { where(scope: FoodsoftMultishared.view_scopes) }
      end
    end
  end

  # set foodcoop scope when adding a new record
  module SetDefaultScope
    def self.included(base) # :nodoc:
      base.class_eval do

        after_initialize :foodsoft_multishared_set_default_scope, if: :new_record?

        private
        def foodsoft_multishared_set_default_scope
          self.scope = FoodsoftConfig.scope
        end
      end
    end
  end

  # restrict users to those who have a matching group
  #   to avoid having duplicate user records, only consider ordergroups
  module ScopeUsers
    def self.included(base) # :nodoc:
      base.class_eval do
        default_scope -> { joins(:groups).readonly(false).where(groups: {scope: FoodsoftMultishared.view_scopes, type: 'Ordergroup'}) unless FoodsoftMultishared.is_master?}
      end
    end
  end

  # restrict GroupOrders to those who have a matching ordergroup
  # TODO - except for the foodcoop sharing its order, which shows all?
  module ScopeOrdergroupAssociation
    def self.included(base) # :nodoc:
      base.class_eval do
        default_scope -> { joins(:ordergroup).readonly(false) unless FoodsoftMultishared.is_master? }
      end
    end
  end
end

# now patch desired controllers to include this
ActiveSupport.on_load(:after_initialize) do
  models = [Group, Order, Supplier, ArticleCategory, Invite, Task]
  models_master = [Group] # master instance has access to all of those from other instances
  models << Message if defined? FoodsoftMessages
  models.each do |model|
    model.send :include, FoodsoftMultishared::ProtectScope
    model.send :include, FoodsoftMultishared::SetDefaultScope
    if models_master.include? model
      model.send :include, FoodsoftMultishared::RestrictScope
    else
      model.send :include, FoodsoftMultishared::RestrictScopeAlways
    end
  end
  User.send :include, FoodsoftMultishared::ScopeUsers
  [GroupOrder, FinancialTransaction].each do |model|
    model.send :include, FoodsoftMultishared::ScopeOrdergroupAssociation
  end
end
