#
# This is a quick hack to get iDEAL payments working without modifying
# foodsoft's database model. Transactions are not stored while in process,
# only on success. Failed transactions leave no trace in the database,
# but they are logged in the server log.
#
# Mollie's check url that is used contains the userid as the last path
# component, so that a financial transaction can be created on success
# for that user and ordergroup.
#
# Perhaps a cleaner approach would be to create a financial transaction
# without amount zero when the payment process starts, and keep track
# of the state using that. Then the transaction id would be enough to
# process it, and also an error message could be given.
#
# Or start using activemerchant - e.g.
#   https://github.com/moneybird/active_merchant_mollie
#
# TODO proper error message without ordergroup
#
class Payments::MollieIdealController < ApplicationController
  before_filter -> { require_plugin_enabled FoodsoftMollie }
  skip_before_filter :authenticate, :only => [:check]
  before_filter :get_ordergroup, only: [:new, :create]
  before_filter :accept_return_to, only: [:new]

  def new
    begin
      @methods = get_mollie.methods.all
      @issuers = get_mollie.issuers.all
    rescue Mollie::API::Exception => error
      # not sure if this actually could happen
      # TODO try this without a proper internet connection and see what happens
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

    # TODO check amount > transaction fee

    payment = get_mollie.payments.create(
      amount: amount,
      description: "#{@ordergroup.id}, #{FoodsoftConfig[:name]}",
      redirectUrl: result_payments_mollie_url,
      webhookUrl: (check_payments_mollie_url unless request.local?), # Mollie doesn't accept localhost here
      method: method,
      issuer: issuer,
      metadata: {
        scope: FoodsoftConfig.scope,
        user: @current_user.id,
        ordergroup: @ordergroup.id
      }
    )

    logger.info "Mollie start: #{amount} for \##{@current_user.id} (#{@current_user.display}) with #{params[:issuer]}"

    redirect_to payment.getPaymentUrl
  rescue Mollie::API::Exception => error
    Rails.logger.info "Mollie create warning: #{error}"
    redirect_to new_payments_mollie_path(session[:mollie_params]), :alert => I18n.t('errors.general_msg', msg: error.message)
  end

  def check
    payment = get_mollie.payments.get params[:id]
    logger.info "Mollie check: #{payment.inspect}"

    if not payment.paid?
      render nothing: true
    elsif payment.metadata.empty?
      # TODO match data with account info
      render plain: 'Error: no metadata'
    else
      user = User.find(payment.metadata[:user])
      ordergroup = Ordergroup.find(payment.metadata[:ordergroup])
      notice = self.ideal_note(payment.id)
      @transaction = FinancialTransaction.new(:user=>user, :ordergroup=>ordergroup, :amount=>payment.amount, :note=>notice)
      @transaction.add_transaction!
      render plain: 'Paid'
    end
  rescue Mollie::API::Exception => error
    Rails.logger.error "Mollie check error: #{error}"
    render plain: "Error: #{error.message}"
  end

  def result
    payment_id = params[:id]
    @transaction = FinancialTransaction.where(:note => self.ideal_note(payment_id)).first
    if @transaction
      logger.info "Mollie result: transaction #{payment_id} succeeded"
      redirect_to_return_or root_path, :notice => I18n.t('payments.mollie_ideal.controller.result.notice')
    else
      logger.info "Mollie result: transaction #{payment_id} failed"
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

  def ideal_note(transaction_id)
    # this is _not_ translated, because this exact string is used to find the transaction
    "iDEAL payment (Mollie #{transaction_id})"
  end

  def get_ordergroup
    # TODO what if the current user doesn't have one?
    @ordergroup = current_user.ordergroup
  end

  # TODO move this to ApplicationController, use it in SessionController too
  # TODO use a stack of return_to urls
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

  def get_mollie
    mollie = Mollie::API::Client.new
    if mcfg = FoodsoftConfig[:mollie]
      mollie.setApiKey mcfg['api_key']
    end
    mollie
  end
end
