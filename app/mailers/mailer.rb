# encoding: utf-8
# ActionMailer class that handles standard emails for Foodsoft.
class Mailer < ApplicationMailer

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

  # separate method to allow plugins to mess with the attachments
  def add_order_result_attachments
    attachments['order.pdf'] = OrderFax.new(@order, @options).to_pdf
    attachments['order.csv'] = OrderCsv.new(@order, @options).to_csv
  end

end
