# Controller for all ordering-actions that are performed by a user who is member of an Ordergroup.
# Management actions that require the "orders" role are handled by the OrdersController.
class GroupOrdersController < ApplicationController
  # Security
  before_filter :ensure_ordergroup_member
  before_filter :parse_order_specifier, :only => [:show, :edit]
  before_filter :get_order_articles, :only => [:show, :edit]
  before_filter :get_article_categories, :only => [:show, :edit]
  #before_filter :ensure_open_order, :only => [:new, :create, :edit, :update, :order, :stock_order, :saveOrder]
  #before_filter :ensure_my_group_order, only: [:show, :edit, :update]
  #before_filter :enough_apples?, only: [:new, :create]

  def index
    @orders = Order.none
    @order_articles = OrderArticle.none
    show
  end

  def show
    @render_totals = true
    @order_articles = @order_articles.joins(:group_order_articles)
                        .includes(order: :group_orders).merge(GroupOrder.where(ordergroup_id: @ordergroup.id))
    unless @order_date == 'current'
      @group_order_details = @ordergroup.group_orders.includes(:order).merge(Order.finished).references(:orders)
                               .select('SUM(price)').group('DATE(orders.ends)').pluck('orders.ends', :price)
                               .map {|(ends,price)| [ends.to_date, price]}

      compute_order_article_details
      render 'show'
    else
      # set all variables used in edit, but render a different template
      edit
      render 'show_current'
    end
  end

  def edit
    @q = OrderArticle.search(params[:q])
    @order_articles = @order_articles.merge(@q.result(distinct: true))
    @order_articles = @order_articles.includes(order: {group_orders: :group_order_articles})

    @current_category = (params[:q][:article_article_category_id_eq].to_i rescue nil)
    @group_orders_sum = @ordergroup.group_orders.includes(:order).merge(Order.open).references(:order).sum(:price)
    compute_order_article_details
  end

  def update
    @group_order.attributes = params[:group_order]
    begin
      @group_order.save_ordering!
      redirect_to group_order_url(@group_order), :notice => I18n.t('group_orders.update.notice')
    rescue ActiveRecord::StaleObjectError
      redirect_to group_orders_url, :alert => I18n.t('group_orders.update.error_stale')
    rescue => exception
      logger.error('Failed to update order: ' + exception.message)
      redirect_to group_orders_url, :alert => I18n.t('group_orders.update.error_general')
    end
  end
  
  private

  # Returns true if @current_user is member of an Ordergroup.
  # Used as a :before_filter by OrdersController.
  def ensure_ordergroup_member
    @ordergroup = @current_user.ordergroup
    if @ordergroup.nil?
      redirect_to root_url, :alert => I18n.t('group_orders.errors.no_member')
    end
  end

  def ensure_open_order
    @order = Order.find((params[:order_id] || params[:group_order][:order_id]),
                        :include => [:supplier, :order_articles])
    unless @order.open?
      flash[:notice] = I18n.t('group_orders.errors.closed')
      redirect_to :action => 'index'
    end
  end

  def ensure_my_group_order
    @group_order = @ordergroup.group_orders.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to group_orders_url, alert: I18n.t('group_orders.errors.notfound')
  end

  def enough_apples?
    if @ordergroup.not_enough_apples?
      redirect_to group_orders_url,
                  alert: t('not_enough_apples', scope: 'group_orders.messages', apples: @ordergroup.apples,
                           stop_ordering_under: FoodsoftConfig[:stop_ordering_under])
    end
  end

  # either 'current', an order end date, or a group_order id
  def parse_order_specifier
    @order_date = params[:id]
    if @order_date == 'current'
      @orders = Order.open
    elsif @order_date
      begin
        # parsing integer group_orders is legacy - dates are used nowadays
        @order_date = Integer(@order_date)
        group_order = @ordergroup.group_orders.where(id: Integer(@order_date)).joins(:order).first
        if group_order
          @order_date = group_order.order.ends.to_date
        else
          redirect_to group_orders_url, alert: I18n.t('group_orders.errors.notfound')
        end
      rescue ArgumentError
        # this is the main flow
        @order_date = @order_date.to_date
      end
      @orders = Order.finished.where('DATE(orders.ends) = ?', @order_date)
    end
  rescue ArgumentError
    @order_date = nil
    @orders = nil
  end

  def get_order_articles
    return unless @orders
    @all_order_articles = OrderArticle.includes(:order, :article).merge(@orders).references(:order)
    @order_articles = @all_order_articles.includes({:article => :supplier}, :article_price)
    @order_articles = @order_articles.page(params[:page]).per(@per_page)
  end

  def get_article_categories
    return unless @all_order_articles
    @article_categories = ArticleCategory.find(@all_order_articles.group(:article_category_id).pluck(:article_category_id))
  end

  # some shared order_article details that need to be done on the final query
  def compute_order_article_details
    @has_open_orders = !@order_articles.select {|oa| oa.order.open?}.empty?
    @has_stock = !@order_articles.select {|oa| oa.order.stockit?}.empty?
    @has_tolerance = !@order_articles.select {|oa| oa.price.unit_quantity > 1}.empty?
    # preload group_order_articles
    @goa_by_oa = Hash[@ordergroup.group_order_articles
                        .where(order_article_id: @order_articles.map(&:id))
                        .map {|goa| [goa.order_article_id, goa]}]
  end

end
