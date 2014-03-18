class OrderArticlesController < ApplicationController

  before_filter :authenticate_finance_or_orders, only: [:create, :edit, :update, :destroy]

  #layout false  # We only use this controller to serve js snippets, no need for layout rendering

  def index
    @order_articles = OrderArticle.includes(:order, :article).merge(Order.open).references(:order)
    @article_categories = ArticleCategory.find(@order_articles.group(:article_category_id).pluck(:article_category_id))

    @order_articles = @order_articles.includes(order: {group_orders: :group_order_articles})
                        .where(group_orders: {ordergroup_id: [@current_user.ordergroup.id, nil]})

    @q = OrderArticle.search(params[:q])
    @order_articles = @order_articles.merge(@q.result(distinct: true))
    @order_articles = @order_articles.includes({:article => :supplier}, :article_price)

    if params[:q].blank? or params[:q].values.compact.empty?
      # if no search given, show shopping cart = only OrderArticles with a GroupOrderArticle
      @order_articles = @order_articles.joins(:group_order_articles)
    end

    @order_articles = @order_articles.page(params[:page]).per(@per_page)

    @has_stock = !@order_articles.select {|oa| oa.order.stockit? }.empty?
    @has_tolerance = !@order_articles.select {|oa| oa.price.unit_quantity > 1}.empty?
    @current_category = (params[:q][:article_article_category_id_eq].to_i rescue nil)
    @group_orders_sum = GroupOrder.includes(:order).merge(Order.open).references(:order).sum(:price)
  end

  # currently used to for order article autocompletion
  def index
    @order = Order.find(params[:order_id])
    if @order.stockit?
      @articles = StockArticle.order('articles.name')
    else
      @articles = @order.supplier.articles.order('articles.name')
    end

    @articles = @articles.where("articles.name LIKE ?", "%#{params[:q]}%")
    respond_to do |format|
      format.json { render :json => search_data(@articles, :name) }
    end
  end

  def new
    @order = Order.find(params[:order_id])
    @order_article = @order.order_articles.build(params[:order_article])
  end

  def create
    @order = Order.find(params[:order_id])
    # The article may be ordered with zero units - in that case do not complain.
    #   If order_article is ordered and a new order_article is created, an error message will be
    #   given mentioning that the article already exists, which is desired.
    @order_article = @order.order_articles.where(:article_id => params[:order_article][:article_id]).first
    unless (@order_article and @order_article.units_to_order == 0)
      @order_article = @order.order_articles.build(params[:order_article])
    end
    @order_article.save!
  rescue
    render action: :new
  end

  def edit
    @order = Order.find(params[:order_id])
    @order_article = OrderArticle.find(params[:id])
  end

  def update
    @order = Order.find(params[:order_id])
    @order_article = OrderArticle.find(params[:id])
    begin
      @order_article.update_article_and_price!(params[:order_article], params[:article], params[:article_price])
    rescue
      render action: :edit
    end
  end

  def destroy
    @order_article = OrderArticle.find(params[:id])
    # only destroy if there are no associated GroupOrders; if we would, the requested
    # quantity and tolerance would be gone. Instead of destroying, we set all result
    # quantities to zero.
    if @order_article.group_order_articles.count == 0
      @order_article.destroy
    else
      @order_article.group_order_articles.each { |goa| goa.update_attribute(:result, 0) }
      @order_article.update_results!
    end
  end


end
