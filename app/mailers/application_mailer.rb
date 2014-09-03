# ActionMailer base class for Foodsoft and plugins
class ApplicationMailer < ActionMailer::Base
  # XXX Quick fix to allow the use of show_user. Proper take would be one of
  #     (1) Use draper, decorate user
  #     (2) Create a helper with this method, include here and in ApplicationHelper
  helper :application
  include ApplicationHelper

  layout 'email'  # Use views/layouts/email.txt.erb

  protected

  # @todo this global stuff gives threading problems when foodcoops have different values! - pass args to `url_for` instead
  def set_foodcoop_scope(foodcoop = FoodsoftConfig.scope)
    [:protocol, :host, :port].each do |k|
      ActionMailer::Base.default_url_options[k] = FoodsoftConfig[k] if FoodsoftConfig[k]
    end
    ActionMailer::Base.default_url_options[:foodcoop] = foodcoop
  end

  # hook mail method to set some defaults
  # @see config/app_config.yml.SAMPLE
  def mail(options={})
    options[:reply_to] ||= options[:from] if options[:from]
    options[:from] = FoodsoftConfig[:email_from] || "\"#{FoodsoftConfig[:name]}\" <#{FoodsoftConfig[:contact]['email']}>"
    options[:sender] ||= FoodsoftConfig[:email_sender]
    super
  end
end
