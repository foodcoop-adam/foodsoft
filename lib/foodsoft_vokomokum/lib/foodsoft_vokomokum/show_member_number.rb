module FoodsoftVokomokum

  # Display member number with user and ordergroup
  module ShowMemberNumber

    def self.included(base) # :nodoc:
      base.class_eval do

        alias_method :foodsoft_vokomokum_show_group, :show_group
        def show_group(group, options = {})
          r = foodsoft_vokomokum_show_group(group, options)
          if group.is_a? Ordergroup and u = group.users.first
            r = "#%03d #{r}" % u.id
          end
          r
        end

        alias_method :foodsoft_vokomokum_show_user, :show_user
        def show_user(user=@current_user, options = {})
          "#%03d #{foodsoft_vokomokum_show_user(user, options)}" % user.id
        end

      end
    end
  end

end

ActiveSupport.on_load(:after_initialize) do
  ApplicationHelper.send :include, FoodsoftVokomokum::ShowMemberNumber
end
