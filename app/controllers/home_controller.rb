# encoding: utf-8
class HomeController < ApplicationController

  def index
    # unaccepted tasks
    @unaccepted_tasks = Task.unaccepted_tasks_for(current_user)
    # task in next week
    @next_tasks = Task.next_assigned_tasks_for(current_user)
    # count tasks with no responsible person
    # tasks for groups the current user is not a member are ignored
    @unassigned_tasks = Task.unassigned_tasks_for(current_user)
  end

  def profile
  end

  def update_profile
    if @current_user.update_attributes(user_params)
      @current_user.ordergroup.update_attributes(ordergroup_params) if ordergroup_params
      session[:locale] = @current_user.locale
      redirect_to my_profile_url, notice: I18n.t('home.changes_saved')
    else
      render :profile
    end
  end

  def ordergroup
    @user = @current_user
    @ordergroup = @user.ordergroup

    unless @ordergroup.nil?

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

      @q = @ordergroup.financial_transactions.search(params[:search])
      @financial_transactions_all = @q.relation.hide_expired.includes(:user).order(sort)
      @financial_transactions = @financial_transactions_all.page(params[:page]).per(@per_page)

      # on first page, include open and closed orders as dummy lines
      if !params[:page]
        @ordergroup.group_orders.in_unsettled_orders.where('group_orders.price != 0')
            .includes(:order => :supplier).order('orders.ends DESC').each do |go|
          note = I18n.t('orders.model.notice_close', :name => go.order.name, :ends => go.order.ends.try{|t| t.strftime(I18n.t('date.formats.default'))})
          @financial_transactions.unshift FinancialTransaction.new amount: -go.price, note: note
        end
      end

    else
      redirect_to root_path, :alert => I18n.t('home.no_ordergroups')
    end
  end

  # cancel personal memberships direct from the myProfile-page
  def cancel_membership
    if params[:membership_id]
      membership = Membership.find(params[:membership_id])
    else
      membership = @current_user.memberships.find_by_group_id(params[:group_id])
    end
    if membership.user == current_user
      membership.destroy
      flash[:notice] = I18n.t('home.ordergroup_cancelled', :group => membership.group.name)
    else
      flash[:error] = I18n.t('errors.general')
    end
    redirect_to my_profile_path
  end

  protected

  def user_params
    params
      .require(:user)
      .permit(:first_name, :last_name, :email, :phone,
              :password, :password_confirmation).merge(params[:user].slice(:settings_attributes))
  end

  def ordergroup_params
    params
      .require(:user)
      .require(:ordergroup)
      .permit(:contact_address)
  end

end
