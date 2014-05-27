# Mollie payment page
class Payments::MollieIdealController < ApplicationController
  before_filter -> { require_plugin_enabled FoodsoftMollie }
  skip_before_filter :authenticate, :only => [:check]
  before_filter :accept_return_to, only: [:new]
  before_filter :get_ordergroup, only: [:new, :create, :result]
  before_filter :get_transaction, only: [:result]

  def new
    begin
      @methods = get_mollie.methods.all
      @issuers = get_mollie.issuers.all
    rescue Mollie::API::Exception => error
      # not sure if this actually could happen
      # @todo try this without a proper internet connection and see what happens
      Rails.logger.info "Mollie new warning: #{error}"
      flash[:error] = I18n.t('errors.general_msg', msg: error.message)
      @methods ||= []
      @issuers ||= []
    end
    @method_options = @methods.map {|m| [m.description, m.id] }
    if @method_options.delete_if {|m| m[1] == 'ideal' }
      @method_options = (@issuers.map {|i| ["iDEAL #{i.name}", "ideal:#{i.id}"]}) + @method_options
    end
    @amount = (params[:amount] or [0, -@ordergroup.get_available_funds].min)
    @amount = [params[:min], @amount].max if params[:min]
  end

  def create
    # store parameters so we can redirect to original form on problems
    session[:mollie_params] = params.select {|k,v| %w(amount label title fixed min text).include?(k)}

    amount = params[:amount].to_f
    amount = [params[:min].to_f, amount].max if params[:min]
    method, issuer = (params[:method]||'').split(':', 2)
    mollie = get_mollie
    mollie_method = mollie.methods.get(method) or raise Exception.new('Invalid method') # @todo i18n message

    # @todo check amount > transaction fee

    @transaction = FinancialTransaction.create!(
      amount: nil,
      ordergroup: @ordergroup,
      user: @current_user,
      payment_method: method,
      payment_plugin: 'mollie',
      payment_amount: amount,
      # @todo payment_currency
      payment_state: 'created',
      note: I18n.t('payments.mollie_ideal.controller.transaction_note', method: mollie_method.description)
    )

    payment = mollie.payments.create(
      amount: amount,
      description: "#{@ordergroup.id}, #{FoodsoftConfig[:name]}",
      redirectUrl: result_payments_mollie_url(id: @transaction.id),
      webhookUrl: (check_payments_mollie_url unless request.local?), # Mollie doesn't accept localhost here
      method: method,
      issuer: issuer,
      metadata: {
        scope: FoodsoftConfig.scope,
        transaction_id: @transaction.id,
        user: @current_user.id,
        ordergroup: @ordergroup.id
      }
    )
    @transaction.update_attributes payment_id: payment.id, payment_state: 'open'

    logger.info "Mollie start: #{amount} for \##{@current_user.id} (#{@current_user.display}) with #{params[:issuer]}"

    redirect_to payment.getPaymentUrl
  rescue Mollie::API::Exception => error
    Rails.logger.info "Mollie create warning: #{error}"
    redirect_to new_payments_mollie_path(session[:mollie_params]), :alert => I18n.t('errors.general_msg', msg: error.message)
  end

  # Endpoint that Mollie calls when a payment status changes.
  def check
    logger.info "Mollie check: #{params[:id]}"
    @transaction = FinancialTransaction.find_by_payment_plugin_and_payment_id('mollie', params[:id])
    logger.debug "  financial transaction: #{@transaction.inspect}"

    render plain: update_status(@transaction)
  rescue Mollie::API::Exception => error
    Rails.logger.error "Mollie check error: #{error}"
    render plain: "Error: #{error.message}"
  end

  # User is redirect here after payment
  def result
    update_status @transaction if request.local? # so localhost works too
    case @transaction.payment_state
    when 'paid'
      logger.info "Mollie result: transaction #{@transaction.id} (#{@transaction.payment_id}) succeeded"
      redirect_to_return_or root_path, :notice => I18n.t('payments.mollie_ideal.controller.result.notice')
    when 'open'
      logger.info "Mollie result: transaction #{@transaction.id} (#{@transaction.payment_id}) waiting for result"
      redirect_to_return_or root_path, :notice => I18n.t('payments.mollie_ideal.controller.result.wait')
    else
      logger.info "Mollie result: transaction #{@transaction.id} (#{@transaction.payment_id}) failed"
      # redirect to form with same parameters as original page
      pms = {foodcoop: FoodsoftConfig.scope}.merge((session[:mollie_params] or {}))
      session[:mollie_params] = nil
      redirect_to new_payments_mollie_path(pms), :alert => I18n.t('payments.mollie_ideal.controller.result.failed') # TODO recall check's response.message
    end
  end

  def cancel
    redirect_to_return_or root_path
  end

  protected

  def get_ordergroup
    # @todo what if the current user doesn't have one?
    @ordergroup = current_user.ordergroup
  end

  def get_transaction
    @transaction = @ordergroup.financial_transactions.find(params[:id])
  end

  # @todo move this to ApplicationController, use it in SessionController too
  # @todo use a stack of return_to urls
  def accept_return_to
    session[:return_to] = nil # or else an unfollowed previous return_to may interfere
    return unless params[:return_to].present?
    if params[:return_to].starts_with?(root_path) or params[:return_to].starts_with?(root_url)
      session[:return_to] = params[:return_to]
    end
  end
  def redirect_to_return_or(fallback_url, options={})
    if session[:return_to].present?
      redirect_to_url = session[:return_to]
      session[:return_to] = nil
    else
      redirect_to_url = fallback_url
    end
    redirect_to redirect_to_url, options
  end

  # Return Mollie client.
  def get_mollie
    mollie = Mollie::API::Client.new
    if mcfg = FoodsoftConfig[:mollie]
      mollie.setApiKey mcfg['api_key']
    end
    mollie
  end

  # Query Mollie status and update financial transaction
  def update_status(transaction)
    payment = get_mollie.payments.get transaction.payment_id
    logger.debug "Mollie update_status: #{payment.inspect}"
    # update some attributes when available
    if payment.details
      transaction.payment_acct_number = payment.details.consumerAccount if payment.details.consumerAccount
      transaction.payment_acct_name = payment.details.consumerName if payment.details.consumerName
    end
    # update status
    case payment.status
    when 'cancelled', 'refunded'
      transaction.update_attributes payment_state: 'cancelled', amount: 0
      return 'cancelled'
    when 'expired'
      transaction.update_attributes payment_state: 'expired', amount: 0
      return 'expired'
    when 'paid', 'paidout'
      payment_fee = FoodsoftMollie.payment_fee payment.amount, transaction.payment_method
      transaction.update_attributes! payment_state: 'paid', amount: payment.amount.to_f-payment_fee.to_f, payment_fee: payment_fee
      return 'paid'
    else
      return nil
    end
  end
end
