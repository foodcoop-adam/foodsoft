# encoding: utf-8
#
# Controller for managing orders, i.e. all actions that require the "orders" role.
# Normal ordering actions of members of order groups is handled by the OrderingController.
class OrdersController < ApplicationController
  
  before_filter :authenticate_orders
  
  # List orders
  def index
    @open_orders = Order.open.includes(:supplier)
    @finished_orders = Order.finished_not_closed.includes(:supplier)
    @per_page = 15
    sort = case (params['sort'] || 'ends')
             when "supplier"         then "suppliers.name, ends DESC"
             when "ends"             then "ends DESC"
             when "pickup"           then "pickup DESC"
             when "supplier_reverse" then "suppliers.name DESC"
             when "ends_reverse"     then "ends"
             when "pickup_reverse"   then "pickup"
             end

    @orders = Order.finished.page(params[:page]).per(@per_page).includes(:supplier).reorder(sort)
  end

  # Gives a view for the results to a specific order
  # Renders also the pdf
  def show
    @doc_options ||= {}
    @order= Order.find(params[:id])
    @view = (params[:view] or 'default').gsub(/[^-_a-zA-Z0-9]/, '')
    @partial = case @view
                 when 'default'  then 'articles'
                 when 'groups'   then 'shared/articles_by/groups'
                 when 'articles' then 'shared/articles_by/articles'
                 else 'articles'
               end

    respond_to do |format|
      format.html
      format.js do
        render :layout => false
      end
      format.pdf do
        pdf = case params[:document]
                when 'groups'   then OrderByGroups.new(@order, @doc_options)
                when 'articles' then OrderByArticles.new(@order, @doc_options)
                when 'fax'      then OrderFax.new(@order, @doc_options)
                when 'matrix'   then OrderMatrix.new(@order, @doc_options)
              end
        send_data pdf.to_pdf, filename: pdf.filename, type: 'application/pdf'
      end
      format.csv do
        send_data OrderCsv.new(@order, @doc_options).to_csv, filename: @order.name+'.csv', type: 'text/csv'
      end
      format.text do
        send_data OrderTxt.new(@order, @doc_options).to_txt, filename: @order.name+'.txt', type: 'text/plain'
      end
    end
  end

  # Page to create a new order.
  def new
    @order = Order.new(supplier_id: params[:supplier_id]).init_dates
  end

  # Save a new order.
  # order_articles will be saved in Order.article_ids=()
  def create
    @order = Order.new(order_params)
    @order.created_by = current_user
    if @order.save
      flash[:notice] = I18n.t('orders.create.notice')
      redirect_to orders_path
    else
      logger.debug "[debug] order errors: #{@order.errors.messages}"
      render :action => 'new'
    end
  end

  # Page to edit an exsiting order.
  # editing finished orders is done in FinanceController
  def edit
    @order = Order.find(params[:id], :include => :articles)
  end

  # Update an existing order.
  def update
    @order = Order.find params[:id]
    if @order.update_attributes order_params
      flash[:notice] = I18n.t('orders.update.notice')
      redirect_to :action => 'show', :id => @order
    else
      render :action => 'edit'
    end
  end

  # Delete an order.
  def destroy
    Order.find(params[:id]).destroy
    redirect_to :action => 'index'
  end
  
  # Finish a current order (js-only)
  def finish
    @order = Order.find params[:id]
    @order_info = params[:order_info] || {}
    @order_info[:sender_name] ||= @current_user.name
    @order_info[:order_contact_name] ||= @current_user.name
    @order_info[:order_contact_phone] ||= @current_user.phone
    @order_info[:message] ||= Mailer.order_result_supplier(@order, [],
                                @order_info.merge({skip_attachments: true, skip_extra: true})).body

    @order_info[:delivered_before] ||= @order.pickup
    # date_picker_time workaround for not using activerecord objects
    if @order_info[:delivered_before_date]
      conv = DateTimeAttribute::Container.new
      conv.date = @order_info[:delivered_before_date]
      conv.time = @order_info[:delivered_before_time]
      @order_info[:delivered_before] = conv.date
    end

    if request.post?
      @order.finish!(@current_user, @order_info)
      flash[:notice] = I18n.t('orders.finish.notice')
      render :action => 'finished'
    end
  rescue => error
    flash[:alert] = I18n.t('errors.general_msg', :msg => error.message)
  end

  def receive
    @order = Order.find(params[:id])
    unless request.post?
      @order_articles = @order.order_articles.ordered_or_member.includes(:article, :article_price).order('articles.order_number, articles.name')
    else
      s = update_order_amounts
      flash[:notice] = (s ? I18n.t('orders.receive.notice', :msg => s) : I18n.t('orders.receive.notice_none'))
      redirect_to @order
    end
  end
  
  def receive_on_order_article_create # See publish/subscribe design pattern in /doc.
    @order_article = OrderArticle.find(params[:order_article_id])
    render :layout => false
  end
  
  def receive_on_order_article_update # See publish/subscribe design pattern in /doc.
    @order_article = OrderArticle.find(params[:order_article_id])
    render :layout => false
  end

  protected
  
  def update_order_amounts
    return if not params[:order_articles]
    # where to leave remainder during redistribution
    rest_to = []
    rest_to << :tolerance if params[:rest_to_tolerance]
    rest_to << :stock if params[:rest_to_stock]
    rest_to << nil
    # count what happens to the articles:
    #   changed, rest_to_tolerance, rest_to_stock, left_over
    counts = [0] * 4
    cunits = [0] * 4
    group_orders = Set.new
    # This was once wrapped in a transaction, but caused
    # "MySQL lock timeout exceeded" errors. It's ok to do
    # this article-by-article anway.
    params[:order_articles].each do |oa_id, oa_params|
      unless oa_params.blank?
        oa = OrderArticle.find(oa_id)
        # update attributes; don't use update_attribute because it calls save
        # which makes received_changed? not work anymore
        oa.attributes = oa_params
        if oa.units_received_changed?
          counts[0] += 1
          unless oa.units_received.blank?
            cunits[0] += oa.units_received * oa.article.unit_quantity
            oacounts = oa.redistribute oa.units_received * oa.price.unit_quantity, rest_to, false
            oacounts.each_with_index {|c,i| cunits[i+1]+=c; counts[i+1]+=1 if c>0 }
            group_orders.merge oa.group_order_articles.map(&:group_order_id)
          end
        end
        oa.save!
      end
    end
    # update dependent fields afterwards (since we passed +false+ to OrderArticle#redistribute) for speed
    group_orders = GroupOrder.find(group_orders.to_a)
    group_orders.each(&:update_price!)
    group_orders.map(&:ordergroup).uniq.each(&:update_stats!)
    return nil if counts[0] == 0
    notice = []
    notice << I18n.t('orders.update_order_amounts.msg1', count: counts[0], units: cunits[0])
    notice << I18n.t('orders.update_order_amounts.msg2', count: counts[1], units: cunits[1]) if params[:rest_to_tolerance]
    notice << I18n.t('orders.update_order_amounts.msg3', count: counts[2], units: cunits[2]) if params[:rest_to_stock]
    if counts[3]>0 or cunits[3]>0
      notice << I18n.t('orders.update_order_amounts.msg4', count: counts[3], units: cunits[3])
    end
    notice.join(', ')
  end

  def order_params
    p = params.require(:order).permit(:supplier_id, :starts_date, :starts_time, :ends_date, :ends_time, :pickup_date, :pickup_time, :note, article_ids: [])
    p[:article_ids] ||= []
    p
  end

end
