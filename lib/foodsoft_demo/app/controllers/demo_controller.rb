class DemoController < ApplicationController

  skip_before_filter :authenticate

  def autologin
    login create_new_user
    # XXX code duplication from SessionController
    if session[:return_to].present?
      redirect_to_url = session[:return_to]
      session[:return_to] = nil
    else
      redirect_to_url = root_url
    end
    redirect_to redirect_to_url
  end

  private

  def create_new_user
    User.transaction do
      # XXX check that simultaneous creation doesn't result in duplicate ideas
      id = (User.maximum(:id) rescue 0) + 1
      user = User.new(first_name: I18n.t('foodsoft_demo.autologin.fields.first_name', id: id),
                      last_name:  I18n.t('foodsoft_demo.autologin.fields.last_name', id: id),
                      email:      I18n.t('foodsoft_demo.autologin.fields.email', id: id),
                      nick:       I18n.t('foodsoft_demo.autologin.fields.nick', id: id))
      user.password = user.new_random_password(8)
      user.ordergroup = {id: 'new'}
      user.save!
      return user
    end
  end

end
