class Payments::AdyenHppController < ApplicationController

  before_filter :get_ordergroup, only: [:new, :create]

  def new
    @amount = params[:amount]
    @amount = [0, -@ordergroup.get_available_funds].min if @amount.blank?
  end

  def create
    # TODO make sure we have an ordergroup
    # store parameters so we can redirect to original form on problems
    #   might put it in merchantReturnData, but if that's too big payment can fail
    session[:adyen_hpp_params] = params.select {|k,v| %w(amount label title fixed).include?(k)}
    redirect_to Adyen::Form.redirect_url(
        :currency_code => FoodsoftConfig[:adyen]['currency'],
        :ship_before_date => Date.today, # TODO perhaps related to pickup day??
        :session_validity => Time.now,
        :recurring => false,
        :merchant_reference => FoodsoftAdyen.encode_notification_data({g: @ordergroup.id}, @ordergroup.name),
        :merchant_account => FoodsoftConfig[:adyen]['merchant_account'],
        :skin_code => FoodsoftConfig[:adyen]['skin_code'],
        :shared_secret => FoodsoftConfig[:adyen]['hmac_key'],
        :payment_amount => (params[:amount].to_f * 100).to_i,
        :shopper_locale => I18n.locale
    )
  end

  def result
    result = params[:authResult].downcase

    unless Adyen::Form.redirect_signature_check(params, FoodsoftConfig[:adyen]['hmac_key'])
      logger.error "foodsoft_adyen result: invalid signature!"
      result = 'error'
    end

    if result == 'authorised' or result == 'pending'
      # success, TODO show message depending on whether we received a notification or not
      logger.info "foodsoft_adyen result: success, status #{result}"
      session[:adyen_hpp_params] = nil
      redirect_to root_path, :notice => I18n.t('payments.adyen_hpp.result.notice_success')

    else
      ['cancelled', 'refused', 'error'].include?(result) or result = 'unknown'
      if result == 'cancelled' or result == 'refused'
        logger.info "foodsoft_adyen result: status #{result}"
      else
        logger.error "foodsoft_adyen result: status #{result}"
      end
      # redirect to form with same parameters as original page
      pms = {foodcoop: FoodsoftConfig.scope}.merge((session[:adyen_hpp_params] or {}))
      session[:adyen_hpp_params] = nil
      redirect_to new_payments_adyen_hpp_path(pms), :alert => I18n.t('payments.adyen_hpp.result.'+result)
    end

  end


  protected

  def get_ordergroup
    # TODO what if the current user doesn't have one?
    @ordergroup = @current_user.ordergroup
  end

end
