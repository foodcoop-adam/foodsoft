# adds a membership payment warning to a number of controllers

module FoodsoftSignup

  # show warning on included controllers
  module SignupWarning
    def self.included(base) # :nodoc:
      base.class_eval do
        before_filter { FoodsoftSignup.signup_warning self, @current_user }
      end
    end
  end

  def self.signup_warning(c, user)
    FoodsoftSignup.enabled? :approval or return true
    return true if FoodsoftConfig[:unapproved_allow_access]=='*'
    if user
      user.role_admin? and return true
      if user.ordergroup.nil?
        c.flash.now[:warning] = I18n.t('foodsoft_signup.errors.no_ordergroup')
      elsif !user.ordergroup.approved?
        c.flash.now[:warning] = approval_msg(c)
      end
    end
    return true
  end

  # don't allow ordering unless approved
  module RequireApproval
    def self.included(base) # :nodoc:
      base.class_eval do
        # patch authenticate, so that iff it's called, also approval is enforced
        alias_method :foodsoft_signup_orig_authenticate, :authenticate
        def authenticate(*args)
          foodsoft_signup_orig_authenticate(*args)
          FoodsoftSignup.check_approval(self, current_user) if current_user
        end
      end
    end
  end

  def self.check_approval(c, user)
    # short checks
    FoodsoftSignup.enabled? :approval or return true
    user and user.role_admin? and return true
    user and user.ordergroup and user.ordergroup.approved? and return true
    # maybe the page is always allowed, test if member can go here
    always_access = (FoodsoftConfig[:unapproved_allow_access] or
      %w(home login sessions signup feedback pages#show pages#all group_orders#archive))
    if always_access == '*' or
       always_access.member?("#{c.params[:controller]}") or
       always_access.member?("#{c.params[:controller]}\##{c.action_name}")
      return true
    end
    if user.nil? or user.ordergroup.nil?
      Rails.logger.warn "FoodsoftSignup: ordergroup required for #{c.params[:controller]}\##{c.action_name}"
      c.redirect_to c.root_url, alert: I18n.t('foodsoft_signup.errors.no_ordergroup')
    elsif !user.ordergroup.approved?
      Rails.logger.warn "FoodsoftSignup: ordergroup approval required for #{c.params[:controller]}\##{c.action_name}"
      c.redirect_to c.root_url, alert: I18n.t('foodsoft_signup.errors.not_approved')
    end
  end

  def self.approval_msg(c)
    if s = FoodsoftConfig[:ordergroup_approval_payment]
      link = c.class.helpers.link_to(I18n.t('foodsoft_signup.payment.msg_link'), payment_link(c))
      msg = if FoodsoftConfig[:ordergroup_approval_msg]
        c.class.helpers.expand_text(FoodsoftConfig[:ordergroup_approval_msg], link: link)
      else
        I18n.t('foodsoft_signup.payment.msg', link: link)
      end
    else
      msg = (c.expand_text(FoodsoftConfig[:ordergroup_approval_msg]) or I18n.t('foodsoft_signup.approval.msg'))
    end
    msg
  end

end

# now patch desired controllers to include this
ActiveSupport.on_load(:after_initialize) do
  ApplicationController.send :include, FoodsoftSignup::RequireApproval
  [HomeController, GroupOrdersController].each do |controller|
    controller.send :include, FoodsoftSignup::SignupWarning
  end
end
