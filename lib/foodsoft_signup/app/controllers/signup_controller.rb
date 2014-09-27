# encoding: utf-8
class SignupController < ApplicationController
  layout 'login'
  skip_before_filter :authenticate # no authentication since this is the signup page

  before_filter :signup_enabled
  before_filter :signup_limit_reached

  def signup
    @user = User.new(params[:user])
    if request.post?
      begin
        # XXX code-duplication from LoginController#accept_invitation
        User.transaction do
          # enforce group (security!)
          @user.ordergroup = {id: 'new'}
          # save!
          if FoodsoftConfig[:use_signup_captcha] and @user.valid? and not valid_captcha? params[:captcha]
            @captcha_invalid = true
          elsif @user.save
            session[:locale] = @user.locale
            # but we proceed slightly differently (TODO same behaviour for invites)
            login @user
            url = if FoodsoftSignup.enabled? :approval and FoodsoftSignup.enabled? :membership_fee
              url = FoodsoftSignup.payment_link self
            else
              nil
            end
            redirect_to url || root_url, notice: I18n.t('signup.controller.notice')
          end
        end
      rescue => e
        Rails.logger.warn "Signup error: #{e}"
        flash[:error] = I18n.t('errors.general_msg', msg: e)
      end
    else
      @user.settings.defaults['profile']['language'] ||= session[:locale]
    end
  end


  protected

  # generate an unique ordergroup name from a user
  # TODO only use from ordergroup model, when wvengen/feature-edit_ordergroup_with_user is merged
  def name_from_user(user)
    if Ordergroup.respond_to? :name_from_user
      Ordergroup.name_from_user user
    else
      name = user.display.truncate(25, omission: '').rstrip
      suffix = 2
      while Ordergroup.where(name: name).exists? do
        name = "#{user.display.trucate(20, omissions: '').rstrip} (#{suffix})"
        suffix += 1
      end
      name
    end
  end

  def signup_enabled
    if not FoodsoftSignup.enabled? :signup
      redirect_to root_url, alert: I18n.t('signup.controller.disabled', foodcoop: FoodsoftConfig[:name])
    elsif not FoodsoftSignup.check_signup_key(params[:key])
      redirect_to root_url, alert: I18n.t('signup.controller.key_wrong', foodcoop: FoodsoftConfig[:name])
    end
  end

  def signup_limit_reached
    if FoodsoftSignup.limit_reached?
      redirect_to root_url, alert: I18n.t('signup.controller.ordergroup_limit',foodcoop: FoodsoftConfig[:name], max: FoodsoftConfig[:signup_ordergroup_limit])
    end
  end

end
