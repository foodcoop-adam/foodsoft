# Controller for all ordering-actions that are performed by a user who is member of an Ordergroup.
# Management actions that require the "orders" role are handled by the OrdersController.
class GroupOrdersController < ApplicationController
  # Security
  before_filter :ensure_ordergroup_member
  before_filter :parse_order_specifier, :only => [:show, :edit, :price_details]
  before_filter :get_order_articles, :only => [:show, :edit, :price_details]
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
                               .group('DATE(orders.ends)').order('DATE(orders.ends) DESC')
      @group_order_details = rails3_pluck(@group_order_details, 'orders.ends', 'SUM(group_orders.price)')
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
    params[:q] ||= params[:search] || {} # for meta_search instead of ransack
    # @todo custom ransack matcher (after moving to Rails 4)
    if params[:article_category_id].blank?
      @current_category_id = nil
    else
      @current_category_id = params[:article_category_id].to_i
      params[:q][:article_article_category_id_in] = ArticleCategory.find(@current_category_id).subtree_ids
    end
    if params[:order_id].blank?
      @current_order_id = nil
    else
      @current_order_id = params[:order_id]
      params[:q][:order_id_eq] = params[:order_id].to_i
    end
    @q = OrderArticle.search(params[:q])
    @order_articles = @order_articles.merge(@q.relation)
    @order_articles = @order_articles.includes(:order)

    compute_order_article_details
    get_article_categories
    @current_category = ArticleCategory.where(id: @current_category_id).first
  end

  def update
    oa_attrs = params[:group_order][:group_order_articles_attributes]
    oa_attrs.keys.each {|key| oa_attrs[key.to_i] = oa_attrs.delete(key)} # Rails 4 - transform_keys
    @orders = Order.where(state: 'open').to_a
    @order_articles = OrderArticle.includes(:article, :article_price).where(id: oa_attrs.keys)
    @order_articles = @order_articles.where(order_id: @orders.map(&:id)) # security!
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

  def price_details
    # only makes sense for current ...
    compute_order_article_details
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
    @order_date = params[:id] || params[:group_order_id]
    if @order_date == 'current'
      @orders = Order.where(state: 'open')
    elsif @order_date == 'last'
      @orders = Order.where(state: 'finished')
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
      @orders = @orders.includes(:supplier).reorder('suppliers.name').to_a
    end
  rescue ArgumentError
    @order_date = nil
    @orders = nil
  end

  def get_order_articles
    return unless @orders
    @all_order_articles = OrderArticle.joins(:article, :order).where(order_id: @orders.map(&:id))
    @order_articles = @all_order_articles.includes({:article => :supplier}, :article_price)
    @order_articles = @order_articles.order('articles.name')
    @order_articles = @order_articles.page(params[:page]).per(@per_page) unless action_name == 'show'
  end

  def get_article_categories
    return unless @all_order_articles
    # get all categories in order_articles and their parents
    @article_categories = ArticleCategory.where(id: @all_order_articles.group(:article_category_id).pluck('articles.article_category_id'))
    @article_categories = ArticleCategory.where(id: @article_categories.map(&:path_ids).flatten.uniq)
  end

  # some shared order_article details that need to be done on the final query
  def compute_order_article_details
    @has_open_orders = @order_articles.select {|oa| oa.order.open?}.any? unless @ordergroup.not_enough_apples?
    @has_stock = @order_articles.select {|oa| oa.order.stockit?}.any?
    @has_tolerance = @order_articles.select {|oa| oa.use_tolerance? }.any?
    @has_boxfill = @order_articles.select {|oa| oa.order.boxfill?}.any?
    @group_orders_prices = rails3_pluck(@ordergroup.group_orders.where(order_id: @orders.map(&:id)),
                                        'SUM(group_orders.price) AS price',
                                        'SUM(group_orders.gross_price) AS gross_price',
                                        'SUM(group_orders.net_price) AS net_price',
                                        'SUM(group_orders.deposit) AS deposit'
                                       ).first
    %w(price gross_price net_price deposit).each {|k| @group_orders_prices[k.to_sym] = @group_orders_prices[k.to_sym].try(:to_f) || 0}
    @group_orders_sum = @group_orders_prices[:price]
    # preload group_order_articles
    @goa_by_oa = Hash[@ordergroup.group_order_articles
                        .where(order_article_id: @order_articles.map(&:id))
                        .map {|goa| [goa.order_article_id, goa]}]
    @order_articles.each {|oa| @goa_by_oa[oa.id] ||= GroupOrderArticle.new(order_article: oa, ordergroup_id: @ordergroup.id)}
  end

  def rails3_pluck(query, *cols)
    cols.each {|col| query = query.select(col)}
    # Rails 3 - http://meltingice.net/2013/06/11/pluck-multiple-columns-rails/
    ActiveRecord::Base.connection.select_all(query).map(&:symbolize_keys)
  end
end
