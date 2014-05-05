module FoodsoftMultishared
  module OrderByScope

    module GroupOrder
      def self.included(base) # :nodoc:
        base.class_eval do
          # override scope
          scope :ordered, -> { includes(:ordergroup).reorder('groups.scope, groups.name') }
        end
      end
    end

    module GroupOrderArticle
      def self.included(base) # :nodoc:
        base.class_eval do
          # override scope
          scope :ordered, -> { includes(group_order: :ordergroup).order('groups.scope, groups.name') }
        end
      end
    end

  end
end

ActiveSupport.on_load(:after_initialize) do
  GroupOrder.send :include, FoodsoftMultishared::OrderByScope::GroupOrder
  GroupOrderArticle.send :include, FoodsoftMultishared::OrderByScope::GroupOrderArticle
end
