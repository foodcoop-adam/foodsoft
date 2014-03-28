# encoding: utf-8
class SignupController < ApplicationController
  layout 'login'
  skip_before_filter :authenticate # no authentication since this is the signup page

  # For anyone
  def signup
    if not FoodsoftSignup.enabled? :signup
      redirect_to root_url, alert: I18n.t('signup.controller.disabled', foodcoop: FoodsoftConfig[:name])
    elsif not FoodsoftSignup.check_signup_key(params[:key])
      redirect_to root_url, alert: I18n.t('signup.controller.key_wrong', foodcoop: FoodsoftConfig[:name])
    else
      @user = User.new(params[:user])
      if request.post?
        begin
          # XXX code-duplication from LoginController#accept_invitation
          User.transaction do
            # enforce group (security!)
            @user.ordergroup = {id: 'new'}
            # save!
            if @user.save
              session[:locale] = @user.locale
              # but we proceed slightly differently (TODO same behaviour for invites)
              login @user
              url = if FoodsoftSignup.enabled? :approval and FoodsoftConfig[:membership_fee] > 0
                url = FoodsoftSignup.payment_link self 
              else
                nil
              end
              redirect_to url || root_url, notice: I18n.t('signup.controller.notice')
            end
          end
        rescue => e
          flash[:error] = I18n.t('errors.general_msg', msg: e)
        end
      else
        @user.settings.defaults['profile']['language'] ||= session[:locale]
        render 'login/accept_invitation', locals: {form_url: signup_path}
      end
    end
  end


  protected

  # generate an unique ordergroup name from a user
  # TODO use from ordergroup model, when wvengen/feature-edit_ordergroup_with_user is merged
  def name_from_user(user)
    name = user.display
    suffix = 2
    while Ordergroup.where(name: name).exists? do
      name = "#{user.display} (#{suffix})"
      suffix += 1
    end
    name
  end

end
