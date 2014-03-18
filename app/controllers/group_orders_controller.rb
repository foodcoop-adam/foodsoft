# Controller for all ordering-actions that are performed by a user who is member of an Ordergroup.
# Management actions that require the "orders" role are handled by the OrdersController.
class GroupOrdersController < ApplicationController
  # Security
  before_filter :ensure_ordergroup_member
  before_filter :parse_order_specifier, :only => [:show]
  #before_filter :ensure_open_order, :only => [:new, :create, :edit, :update, :order, :stock_order, :saveOrder]
  #before_filter :ensure_my_group_order, only: [:show, :edit, :update]
  #before_filter :enough_apples?, only: [:new, :create]

  def show
    if @orders
      @all_order_articles = OrderArticle.includes(:order, :article).merge(@orders).references(:order)
      @order_articles = @all_order_articles.includes({:article => :supplier}, :article_price)
      @order_articles = @order_articles.page(params[:page]).per(@per_page)
    end

    if @order_date == 'current'
      current

    else
      @group_order_details = @ordergroup.group_orders.includes(:order).merge(Order.finished).references(:orders).
                              select('SUM(price)').group('DATE(orders.ends)').pluck('orders.ends', :price).
                              map {|(ends,price)| [ends.to_date, price]}

      @order_articles = @order_articles.joins(:group_order_articles)
      compute_order_article_details
    end
  end

  def current
    @article_categories = ArticleCategory.find(@all_order_articles.group(:article_category_id).pluck(:article_category_id))
    @current_category = (params[:q][:article_article_category_id_eq].to_i rescue nil)

    @q = OrderArticle.search(params[:q])
    @order_articles = @order_articles.merge(@q.result(distinct: true))

    @order_articles = @order_articles.includes(order: {group_orders: :group_order_articles})
    #                    .where(group_orders: {ordergroup_id: [@ordergroup.id, nil]})

    if params[:q].blank? or params[:q].values.compact.empty?
      # if no search given, show shopping cart = only OrderArticles with a GroupOrderArticle
      @order_articles = @order_articles.joins(:group_order_articles)
    end

    compute_order_article_details
    @group_orders_sum = GroupOrder.includes(:order).merge(Order.open).references(:order).sum(:price)

    render 'current'
  end

  def create
    @group_order = GroupOrder.new(params[:group_order])
    begin
      @group_order.save_ordering!
      redirect_to group_order_url(@group_order), :notice => I18n.t('group_orders.create.notice')
    rescue ActiveRecord::StaleObjectError
      redirect_to group_orders_url, :alert => I18n.t('group_orders.create.error_stale')
    rescue => exception
      logger.error('Failed to update order: ' + exception.message)
      redirect_to group_orders_url, :alert => I18n.t('group_orders.create.error_general')
    end
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
  
  # Shows all Orders of the Ordergroup
  # if selected, it shows all orders of the foodcoop
  def archive
    # get only orders belonging to the ordergroup
    @closed_orders = Order.closed.page(params[:page]).per(10)

    respond_to do |format|
      format.html # archive.html.haml
      format.js   # archive.js.erb
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
        @order_date = Order.joins(:group_orders).where(group_orders: {id: @order_date}).first.ends.to_date
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

  # some shared order_article details that need to be done on the final query
  def compute_order_article_details
    @has_open_orders = !@order_articles.select {|oa| oa.order.open?}.empty?
    @has_stock = !@order_articles.select {|oa| oa.order.stockit?}.empty?
    @has_tolerance = !@order_articles.select {|oa| oa.price.unit_quantity > 1}.empty?
  end

end
