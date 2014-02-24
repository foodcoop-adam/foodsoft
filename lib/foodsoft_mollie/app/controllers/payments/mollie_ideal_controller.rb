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
class Payments::MollieIdealController < ApplicationController
  skip_before_filter :authenticate, :only => [:check]
  before_filter :get_ordergroup, only: [:new, :create]

  def new
    set_mollie_cfg
    @banks = IdealMollie.banks
    @amount = (params[:amount] or [0, -@ordergroup.get_available_funds].min)
  end

  def create
    # store parameters so we can redirect to original form on problems
    session[:mollie_params] = params.select {|k,v| %w(amount label title fixed).include?(k)}

    bank_id = params[:bank_id]
    amount = params[:amount].to_f

    set_mollie_cfg
    IdealMollie::Config.return_url = result_payments_mollie_url
    IdealMollie::Config.report_url = check_payments_mollie_url(:id => @current_user.id)
    request = IdealMollie.new_order((amount*100.0).to_i, @current_user.nick, bank_id)

    transaction_id = request.transaction_id
    logger.info "iDEAL start: #{amount} for \##{@current_user.id} (#{@current_user.display}) with bank #{bank_id}"

    redirect_to request.url
  end

  def check
    set_mollie_cfg
    transaction_id = params[:transaction_id]
    response = IdealMollie.check_order(transaction_id)
    logger.info "iDEAL check: #{response.inspect}"

    if response.paid
      user = User.find(params[:id])
      notice = self.ideal_note(transaction_id)
      amount = response.amount/100.0
      @transaction = FinancialTransaction.new(:user=>user, :ordergroup=>user.ordergroup, :amount=>amount, :note=>notice)
      @transaction.add_transaction!
    end
    render :nothing => true
  end

  def result
    transaction_id = params[:transaction_id]
    @transaction = FinancialTransaction.where(:note => self.ideal_note(transaction_id)).first
    if @transaction
      logger.info "iDEAL result: transaction #{transaction_id} succeeded"
      redirect_to root_path, :notice => I18n.t('payments.mollie_ideal.controller.result.notice')
    else
      logger.info "iDEAL result: transaction #{transaction_id} failed"
      # redirect to form with same parameters as original page
      pms = {foodcoop: FoodsoftConfig.scope}.merge((session[:mollie_params] or {}))
      session[:mollie_params] = nil
      redirect_to new_payments_mollie_path(pms), :alert => I18n.t('payments.mollie_ideal.controller.result.failed') # TODO recall check's response.message
    end
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

  def set_mollie_cfg
    if mcfg = FoodsoftConfig[:mollie]
      puts "yay! #{mcfg.inspect}"
      IdealMollie::Config.partner_id  = mcfg['partner_id']  if mcfg['partner_id']
      IdealMollie::Config.profile_key = mcfg['profile_key'] if mcfg['profile_key']
      IdealMollie::Config.test_mode   = mcfg['test_mode']   if mcfg['test_mode']
    end
  end
end
