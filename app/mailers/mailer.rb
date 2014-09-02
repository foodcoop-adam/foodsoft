# encoding: utf-8
# ActionMailer class that handles all emails for the FoodSoft.
class Mailer < ActionMailer::Base
  # XXX Quick fix to allow the use of show_user. Proper take would be one of
  #     (1) Use draper, decorate user
  #     (2) Create a helper with this method, include here and in ApplicationHelper
  helper :application
  include ApplicationHelper

  layout 'email'  # Use views/layouts/email.txt.erb

  # Sends an email with instructions on how to reset the password.
  # Assumes user.setResetPasswordToken has been successfully called already.
  def reset_password(user)
    set_foodcoop_scope
    @user = user
    @link = new_password_url(id: @user.id, token: @user.reset_password_token)

    mail :to => @user.email,
         :subject => "[#{FoodsoftConfig[:name]}] " + I18n.t('mailer.reset_password.subject', :username => show_user(@user))
  end
    
  # Sends an invite email.
  def invite(invite)
    set_foodcoop_scope
    @invite = invite
    @link = accept_invitation_url(token: @invite.token)

    mail :to => @invite.email,
         :subject => I18n.t('mailer.invite.subject')
  end

  # Notify user of upcoming task.
  def upcoming_tasks(user, task)
    set_foodcoop_scope
    @user = user
    @task = task

    mail :to => user.email,
         :subject =>  "[#{FoodsoftConfig[:name]}] " + I18n.t('mailer.upcoming_tasks.subject')
  end

  # Sends order result for specific Ordergroup
  def order_result(user, group_order)
    set_foodcoop_scope
    @order        = group_order.order
    @group_order  = group_order

    mail :to => user.email,
         :subject => "[#{FoodsoftConfig[:name]}] " + I18n.t('mailer.order_result.subject', :name => group_order.order.name)
  end

  # Notify user if account balance is less than zero
  def negative_balance(user,transaction)
    set_foodcoop_scope
    @group        = user.ordergroup
    @transaction  = transaction

    mail :to => user.email,
         :subject => "[#{FoodsoftConfig[:name]}] " + I18n.t('mailer.negative_balance.subject')
  end

  def feedback(user, feedback)
    set_foodcoop_scope
    @user = user
    @feedback = feedback

    mail :to => FoodsoftConfig[:notification]["error_recipients"],
         :from => "#{show_user user} <#{user.email}>",
         :subject => "[#{FoodsoftConfig[:name]}] " + I18n.t('mailer.feedback.subject', :email => user.email)
  end

  def not_enough_users_assigned(task, user)
    set_foodcoop_scope
    @task = task
    @user = user

    mail :to => user.email,
         :subject => "[#{FoodsoftConfig[:name]}] " + I18n.t('mailer.not_enough_users_assigned.subject', :task => task.name)
  end

  # Send message with order to supplier
  layout nil, only: :order_result_supplier
  def order_result_supplier(order, to, options={})
    set_foodcoop_scope
    @order = order
    @options = options

    add_order_result_attachments unless options[:skip_attachments]

    subject = I18n.t("mailer.order_result_supplier.subject#{options[:delivered_before] and '_with_date'}",
                    delivered_before: options[:delivered_before])

    mail :to => to[0],
         :cc => to[1..-1],
         :subject => "[#{FoodsoftConfig[:name]}] #{subject}"
  end


  private

  # @todo this global stuff gives threading problems when foodcoops have different values! - pass args to `url_for` instead
  def set_foodcoop_scope(foodcoop = FoodsoftConfig.scope)
    [:protocol, :host, :port].each do |k|
      ActionMailer::Base.default_url_options[k] = FoodsoftConfig[k] if FoodsoftConfig[k]
    end
    ActionMailer::Base.default_url_options[:foodcoop] = foodcoop
  end

  # separate method to allow plugins to mess with the attachments
  def add_order_result_attachments
    attachments['order.pdf'] = OrderFax.new(@order, @options).to_pdf
    attachments['order.csv'] = OrderCsv.new(@order, @options).to_csv
  end

  # using after_action to allow different scopes and optional defaults
  def mail(options={})
    options[:from] ||= FoodsoftConfig[:email_from] || "\"#{FoodsoftConfig[:name]}\" <#{FoodsoftConfig[:contact]['email']}>"
    options[:sender] ||= FoodsoftConfig[:email_sender]
    options[:reply_to] ||= FoodsoftConfig[:email_replyto] if FoodsoftConfig[:email_replyto]
    super
  end

end
