module FoodsoftMultishared
  module GroupUniqueness

    module FixOrdergroup
      def self.included(base) # :nodoc:
        base.class_eval do

          private
          # TODO fix code duplication from Ordergroup

          def uniqueness_of_name
            group = Ordergroup.unscoped.where('groups.name = ?', name)
            group = group.where('groups.id != ?', self.id) unless new_record?
            if group.exists?
              message = group.first.deleted? ? :taken_with_deleted : :taken
              errors.add :name, message
            end
          end

          def self.name_from_user(user)
            name = user.display.truncate(25, omission: '').rstrip
            suffix = 2
            while Ordergroup.unscoped.where(name: name).exists? do
              name = "#{user.display.truncate(20, omission: '').rstrip} (#{suffix})"
              suffix += 1
            end
            name
          end

        end
      end
    end

  end
end

# now patch desired controllers to include this
ActiveSupport.on_load(:after_initialize) do
  Ordergroup.send :include, FoodsoftMultishared::GroupUniqueness::FixOrdergroup
end
