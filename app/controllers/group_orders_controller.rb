# Controller for all ordering-actions that are performed by a user who is member of an Ordergroup.
# Management actions that require the "orders" role are handled by the OrdersController.
class GroupOrdersController < ApplicationController
  # Security
  before_filter :ensure_ordergroup_member
  before_filter :parse_order_specifier, :only => [:show, :edit]
  before_filter :get_order_articles, :only => [:show, :edit]
  before_filter :enough_apples?, only: [:edit, :update]

  def index
    @orders = Order.where(id: nil) # Rails 4: Order.none
    @order_articles = OrderArticle.where(id: nil) # Rails 4: OrderArticle.none
    show
  end

  def show
    @render_totals = true
    @order_articles = @order_articles.includes(:group_order_articles => :group_order)
                        .where(group_orders: {ordergroup_id: @ordergroup.id})
    unless @order_date == 'current'
      @group_order_details = @ordergroup.group_orders.joins(:order => :supplier).merge(Order.finished)
                               .group('DATE(orders.ends)').select('orders.ends').select('SUM(group_orders.price)')
                               .order('DATE(orders.ends) DESC')
      # Rails 3 - http://meltingice.net/2013/06/11/pluck-multiple-columns-rails/
      @group_order_details = ActiveRecord::Base.connection.select_all(@group_order_details)
                               .map {|a| [a.values[0].to_date, a.values[1]]}

      compute_order_article_details
      render 'show'
    else
      # set all variables used in edit, but render a different template
      edit
      render 'show_current'
    end
  end

  def edit
    params[:q] ||= params[:search] # for meta_search instead of ransack
    @q = OrderArticle.search(params[:q])
    @order_articles = @order_articles.merge(@q.relation)
    @order_articles = @order_articles.includes(:order)

    @current_category = (params[:q][:article_article_category_id_eq].to_i rescue nil)
    compute_order_article_details
    get_article_categories
  end

  def update
    oa_attrs = params[:group_order][:group_order_articles_attributes]
    oa_attrs.keys.each {|key| oa_attrs[key.to_i] = oa_attrs.delete(key)} # Rails 4 - transform_keys
    @order_articles = OrderArticle.includes(:order, :article, :article_price).where(id: oa_attrs.keys) 
    @order_articles = @order_articles.where(orders: {state: 'open'}) # security!
    compute_order_article_details

    GroupOrder.transaction do
      @order_articles.each do |oa|
        oa_attr = oa_attrs[oa.id]
        goa = @goa_by_oa[oa.id]
        goa.update_quantities oa_attr['quantity'].to_i, oa_attr['tolerance'].to_i||0
        oa.update_results!
      end
      @ordergroup.group_orders.where(order_id: @order_articles.map(&:order_id).uniq).map(&:update_price!)
    end
    respond_to do |format|
      format.html { redirect_to group_order_url(:current), :notice => I18n.t('group_orders.update.notice') }
      format.js
    end

  rescue => e
    logger.error('Failed to update order: ' + e.message)
    respond_to do |format|
      format.html { redirect_to group_orders_url(:current), :alert => I18n.t('group_orders.update.error_general') }
      format.js   { flash[:alert] = I18n.t('group_orders.update.error_general') }
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
      @orders = Order.where(state: 'open')
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
        @order_date = (@order_date.to_date rescue nil)
      end
      @orders = Order.where(state: ['finished', 'closed']).where('DATE(orders.ends) = ?', @order_date) if @order_date
    end
  rescue ArgumentError
    @order_date = nil
    @orders = nil
  end

  def get_order_articles
    return unless @orders
    @all_order_articles = OrderArticle.joins(:article, :order).merge(@orders)
    @order_articles = @all_order_articles.includes({:article => :supplier}, :article_price)
    @order_articles = @order_articles.page(params[:page]).per(@per_page)
  end

  def get_article_categories
    return unless @all_order_articles
    @article_categories = ArticleCategory.find(@all_order_articles.group(:article_category_id).pluck('articles.article_category_id'))
  end

  # some shared order_article details that need to be done on the final query
  def compute_order_article_details
    @has_open_orders = !@order_articles.select {|oa| oa.order.open?}.empty? unless @ordergroup.not_enough_apples?
    @has_stock = !@order_articles.select {|oa| oa.order.stockit?}.empty?
    @has_tolerance = !@order_articles.select {|oa| oa.price.unit_quantity > 1}.empty?
    @group_orders_sum = @ordergroup.group_orders.includes(:order).merge(@orders).sum(:price)
    # preload group_order_articles
    @goa_by_oa = Hash[@ordergroup.group_order_articles
                        .where(order_article_id: @order_articles.map(&:id))
                        .map {|goa| [goa.order_article_id, goa]}]
    @order_articles.each {|oa| @goa_by_oa[oa.id] ||= GroupOrderArticle.new(order_article: oa, ordergroup_id: @ordergroup.id)}
  end

end
