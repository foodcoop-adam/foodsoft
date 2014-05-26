# encoding: utf-8
class Finance::FinancialTransactionsController < ApplicationController
  before_filter :authenticate_finance
  before_filter :paymanual_enabled, :except => [:index, :index_collection]
  before_filter :find_ordergroup, :except => [:new_collection, :create_collection, :index_collection]
  inherit_resources
#  belongs_to :ordergroup

  def index
    if params['sort']
      sort = case params['sort']
               when "date"  then "created_on"
               when "note"   then "note"
               when "amount" then "amount"
               when "date_reverse"  then "created_on DESC"
               when "note_reverse" then "note DESC"
               when "amount_reverse" then "amount DESC"
               end
    else
      sort = "created_on DESC"
    end

    @q = FinancialTransaction.search(params[:search])
    @financial_transactions_all = @q.relation.hide_expired.includes(:user).order(sort)
    @financial_transactions_all = @financial_transactions_all.where(ordergroup_id: @ordergroup.id) if @ordergroup
    @financial_transactions = @financial_transactions_all.page(params[:page]).per(@per_page)

    respond_to do |format|
      format.js; format.html { render }
      format.csv do
        send_data FinancialTransactionsCsv.new(@financial_transactions_all).to_csv, filename: 'transactions.csv', type: 'text/csv'
      end
    end
  end

  def index_collection
    index
  end

  def new
    @financial_transaction = @ordergroup.financial_transactions.build
    # pre-fill amount to bring balance to zero - including unfinished and open orders!! #foodcoop-adam
    if @ordergroup.get_available_funds < 0
      @financial_transaction.amount = -@ordergroup.get_available_funds
    end
  end

  def create
    # handle note radio buttons
    if params[:type] == 'pin'
      params[:financial_transaction][:note] = 'PIN delivery day. ' + params[:financial_transaction][:note]
    elsif params[:type] == 'cash'
      params[:financial_transaction][:note] = 'cash delivery day. ' + params[:financial_transaction][:note]
    end
    transaction_params = params[:financial_transaction].merge({payment_method: 'manual', payment_state: 'paid'})
    @financial_transaction = FinancialTransaction.new transaction_params
    @financial_transaction.user = current_user
    @financial_transaction.save!
    redirect_to finance_ordergroup_transactions_url(@ordergroup), notice: I18n.t('finance.financial_transactions.controller.create.notice')
  rescue ActiveRecord::RecordInvalid => error
    flash.now[:alert] = error.message
    render :action => :new
  end

  def new_collection
  end

  def create_collection
    raise I18n.t('finance.financial_transactions.controller.create_collection.error_note_required') if params[:note].blank?
    params[:financial_transactions].each do |trans|
      # ignore empty amount fields ...
      unless trans[:amount].blank?
        Ordergroup.find(trans[:ordergroup_id]).add_financial_transaction!(trans[:amount], params[:note], @current_user)
      end
    end
    redirect_to finance_ordergroups_url, notice: I18n.t('finance.financial_transactions.controller.create_collection.notice')
  rescue => error
    redirect_to finance_new_transaction_collection_url, alert: I18n.t('finance.financial_transactions.controller.create_collection.alert', error: error.to_s)
  end

  protected

  def find_ordergroup
    @ordergroup = Ordergroup.find(params[:ordergroup_id])
  end

  def paymanual_enabled
    unless FoodsoftConfig[:use_paymanual]
      redirect_to finance_ordergroups_url, alert: I18n.t('finance.financial_transactions.controller.paymanual_disabled')
    end
  end

end
