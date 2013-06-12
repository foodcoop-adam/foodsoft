# encoding: utf-8
class Finance::FinancialTransactionsController < ApplicationController
  before_filter :authenticate_finance
  before_filter :find_ordergroup, :except => [:new_collection, :create_collection]
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

    @financial_transactions = @ordergroup.financial_transactions.includes(:user).order(sort).
        page(params[:page]).per(@per_page)
    if params[:query].present?
      @financial_transactions = @financial_transactions.where('note LIKE ?', "%#{params[:query]}%")
    end
  end

  def new
    @financial_transaction = @ordergroup.financial_transactions.build
    # pre-fill amount to bring balance to zero - including unfinished and open orders!! #foodcoop-adam
    if @ordergroup.get_available_funds < 0
      @financial_transaction.amount = -@ordergroup.get_available_funds
    end
  end

  def create
    @financial_transaction = FinancialTransaction.new(params[:financial_transaction])
    @financial_transaction.user = current_user
    @financial_transaction.add_transaction!
    redirect_to finance_ordergroup_transactions_url(@ordergroup), notice: t('finance.financial_transactions.create.notice')
  rescue ActiveRecord::RecordInvalid => error
    flash.now[:alert] = error.message
    render :action => :new
  end

  def new_collection
  end

  def create_collection
    raise "Notiz wird benötigt!" if params[:note].blank?
    params[:financial_transactions].each do |trans|
      # ignore empty amount fields ...
      unless trans[:amount].blank?
        Ordergroup.find(trans[:ordergroup_id]).add_financial_transaction!(trans[:amount], params[:note], @current_user)
      end
    end
    redirect_to finance_ordergroups_url, notice: t('finance.create_collection.create.notice')
  rescue => error
    redirect_to finance_new_transaction_collection_url, alert: t('finance.create_collection.create.alert', error: error.to_s)
  end

  protected

  def find_ordergroup
    @ordergroup = Ordergroup.find(params[:ordergroup_id])
  end

end
