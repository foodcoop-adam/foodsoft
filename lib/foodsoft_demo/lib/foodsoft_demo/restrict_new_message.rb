if defined? FoodsoftMessages
  module FoodsoftDemo
    module RestrictNewMessage
      def self.included(base) # :nodoc:
        base.class_eval do

          before_filter :foodsoft_demo_restrict_new_message, only: [:new, :create]

          private
          def foodsoft_demo_restrict_new_message
            if FoodsoftDemo.enabled? :restrict_new_message
              unless FoodsoftConfig[:restrict_new_message] == 'admin' and current_user.try(:role_admin?)
                flash[:warning] = I18n.t('foodsoft_demo.restrict_new_message.notice_disabled')
                redirect_to root_path
              end
            end
          end

        end
      end
    end
  end

  ActiveSupport.on_load(:after_initialize) do
    MessagesController.send :include, FoodsoftDemo::RestrictNewMessage
  end
end
