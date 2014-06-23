require 'deface'
require 'foodsoft_signup/engine'
require 'foodsoft_signup/hooks'
require 'foodsoft_signup/membership_fee'

module FoodsoftSignup
  def self.enabled?(what)
    case what
    when :signup
      if not FoodsoftConfig[:use_signup].nil?
        FoodsoftConfig[:use_signup]
      else
        # fallback to old configuration option
        FoodsoftConfig[:signup]
      end

    when :approval
      # when approval is not explicitely disabled and signup is enabled,
      # default to using approval - better be safe (see README for details)
      if FoodsoftConfig[:use_approval].nil? or FoodsoftConfig[:use_approval].to_s == 'signup'
        enabled?(:signup)
      else
        FoodsoftConfig[:use_approval]
      end

    when :membership_fee
      FoodsoftConfig[:membership_fee].to_f > 0

    else
      Rails.logger.warn "FoodsoftSignup.enabled? called with unknown parameter #{what}"
      nil
    end
  end

  # checks signup key - or returns true no key is required
  def self.check_signup_key(key)
    cfg = enabled?(:signup)
    if FoodsoftConfig[:signup_key].nil?
      # either no key, or legacy when key was set in use_signup
      cfg == true or cfg == key
    else
      cfg == true and FoodsoftConfig[:signup_key] == key
    end
  end

  def self.payment_link(c)
    (s = FoodsoftConfig[:ordergroup_approval_payment]) or return nil
    url = if s.match(/^https?:/i)
      s
    else
      c.send s.to_sym
    end
    params = {
      amount: FoodsoftConfig[:membership_fee],
      label: FoodsoftConfig[:ordergroup_approval_payment_label] || I18n.t('foodsoft_signup.payment.pay_label'),
      title: FoodsoftConfig[:ordergroup_approval_payment_title] || I18n.t('foodsoft_signup.payment.pay_title')
    }
    params[:text] = c.class.helpers.expand_text(FoodsoftConfig[:ordergroup_approval_payment_text], params) if FoodsoftConfig[:ordergroup_approval_payment_text]
    if FoodsoftConfig[:membership_fee_fixed] == false or FoodsoftConfig[:membership_fee_donate]
      params[:min] = FoodsoftConfig[:membership_fee]
    else
      params[:fixed] = 'true'
    end
    url + '?' + params.to_param
  end

  # returns whether the ordergroup signup limit has been reached or not
  def self.limit_reached?
    limit = FoodsoftConfig[:signup_ordergroup_limit]
    return unless limit
    groups = Ordergroup
    groups = groups.where(approved: true) if enabled?(:approval)
    groups.count >= limit.to_i
  end
end
