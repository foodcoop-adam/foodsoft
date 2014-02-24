# This could have been done using a Deface override. The current
# approach may have a slightly better performance. But there's another
# reason why we're using content_for_in_controllers. The view that's
# overridden has both an html and a javascript template. When a
# Deface override is present for the html view (and that's where the
# button is added), it is also enabled for the javascript view. That
# means that the template is parsed as xml, and rewritten. Result:
# all entities are escaped, and the javascript is not valid anymore.

module FoodsoftMailall
  module AddButton
    def self.included(base) # :nodoc:
      base.class_eval do
        before_filter :add_mailall_button, only: :index

        protected

        def add_mailall_button
          # Only render for html, because that's the only place we need it.
          # If we do this for javascript, the served content-type becomes html instead of js.
          if request.negotiate_mime([Mime::JS, Mime::HTML]) == Mime::HTML
            content_for :actionbar, view_context.render('admin/mailall/menu_button')
          end
        end

      end
    end
  end
end

ActiveSupport.on_load(:after_initialize) do
  Admin::UsersController.send :include, FoodsoftMailall::AddButton
end
