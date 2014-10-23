# encoding: utf-8
#
class Order < ActiveRecord::Base
  attr_accessor :ignore_warnings

  # Associations
  has_many :order_articles, :dependent => :destroy
  has_many :articles, :through => :order_articles
  has_many :group_orders, :dependent => :destroy
  has_many :ordergroups, :through => :group_orders
  has_one :invoice
  has_many :comments, :class_name => "OrderComment", :order => "created_at"
  has_many :stock_changes
  belongs_to :supplier
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_user_id'
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_user_id'

  # Validations
  validates_presence_of :starts
  validate :starts_before_ends, :starts_and_ends_before_pickup, :include_articles
  validate :keep_ordered_articles

  # Callbacks
  after_save :save_order_articles, :update_price_of_group_orders

  # Finders
  # joins needn't be readonly - https://github.com/rails/rails/issues/10769
  scope :ordered_open, joins(:supplier).readonly(false).order('ends ASC', 'suppliers.name ASC')
  scope :ordered_finished, includes(:supplier).readonly(false).order('DATE(ends) DESC', 'suppliers.name ASC')

  scope :open, where(state: 'open').ordered_open
  scope :finished, where(state: ['finished', 'closed']).ordered_finished
  scope :finished_not_closed, where(state: 'finished').ordered_finished
  scope :closed, where(state: 'closed').ordered_finished
  scope :stockit, where(supplier_id: 0).order('ends DESC')

  scope :recent, :order => 'starts DESC', :limit => 10

  # Allow separate inputs for date and time
  include DateTimeAttribute
  date_time_attribute :starts, :ends, :pickup

  def stockit?
    supplier_id == 0
  end

  def name
    stockit? ? I18n.t('orders.model.stock') : supplier.name
  end

  # returns whether this order meets the criteria for sending it to the supplier
  # returns true, or a reason
  # Please note that this does not take into account whether there is an email address
  # to send the order to, just whether it is ready for sending.
  def can_send
    # never for stock orders!
    stockit? and return :stockit
    # need articles to order
    order_articles.ordered.count > 0 or return :result
    # if we have a number as minimum order quantity, check it
    min_order_quantity_reached != false or return :min_quantity
    return true
  end

  # returns whether the order reaches the minimum order quantity:
  #   true    if gross order sum reaches minimum order quantity
  #   false   if not
  #   nil     if there is no minimum order quantity price (note that
  #           there may still be a free-form text min_order_quantity)
  def min_order_quantity_reached
    stockit? and return nil
    min_order_quantity = supplier.min_order_quantity_price or return nil
    return sum(:gross) >= min_order_quantity
  end

  # list of email addresses to send the order to when finished
  # returns nil if `send_order_on_finish` foodcoop config is not set
  def order_send_emails
    return unless FoodsoftConfig[:send_order_on_finish]
    return unless supplier.order_send_email or FoodsoftConfig[:send_order_on_finish] == 'cc_only'
    to = FoodsoftConfig[:send_order_on_finish_cc] || []
    to.map! do |a|
      if a == '%{contact.email}'
        (FoodsoftConfig[:contact]['email'] rescue nil)
      else
        a
      end
    end.compact!
    to = [supplier.order_send_email] + to unless FoodsoftConfig[:send_order_on_finish] == 'cc_only'
    to
  end

  def articles_for_ordering
    if stockit?
      # make sure to include those articles which are no longer available
      # but which have already been ordered in this stock order
      StockArticle.available.all(:include => :article_category,
        :order => 'article_categories.name, articles.name').reject{ |a|
        a.quantity_available <= 0 and not a.ordered_in_order?(self)
      }.group_by { |a| a.article_category.name }
    else
      supplier.articles.available.all.group_by { |a| a.article_category.name }
    end
  end

  def supplier_articles
    if stockit?
      StockArticle.undeleted.reorder('articles.name')
    else
      supplier.articles.undeleted.reorder('articles.name')
    end
  end

  # Save ids, and create/delete order_articles after successfully saved the order
  def article_ids=(ids)
    @article_ids = ids
  end

  def article_ids
    @article_ids ||= order_articles.map { |a| a.article_id.to_s }
  end

  # Returns an array of article ids that lead to a validation error.
  def erroneous_article_ids
    @erroneous_article_ids ||= []
  end

  def open?
    state == "open"
  end

  def finished?
    state == "finished"
  end

  def closed?
    state == "closed"
  end

  def expired?
    !ends.nil? && ends < Time.now
  end

  # sets up first guess of dates when initializing a new object
  # I guess `def initialize` would work, but it's tricky http://stackoverflow.com/questions/1186400
  def init_dates
    self.starts ||= Time.now
    if FoodsoftConfig[:order_schedule]
      # try to be smart when picking a reference day
      last = (DateTime.parse(FoodsoftConfig[:order_schedule]['initial']) rescue nil)
      last ||= Order.finished.reorder(:pickup).where('pickup IS NOT NULL').first.try(:pickup)
      last ||= self.starts
      # adjust end and pickup dates
      self.ends   ||= FoodsoftDateUtil.next_occurrence last, self.starts,
                        FoodsoftConfig[:order_schedule]['ends']
      self.pickup ||= FoodsoftDateUtil.next_occurrence last, self.starts,
                        FoodsoftConfig[:order_schedule]['pickup']
    end
    self
  end

  # search GroupOrder of given Ordergroup
  def group_order(ordergroup)
    group_orders.where(:ordergroup_id => ordergroup.id).first
  end

  # Returns OrderArticles in a nested Array, grouped by category and ordered by article name.
  # The array has the following form:
  # e.g: [["drugs",[teethpaste, toiletpaper]], ["fruits" => [apple, banana, lemon]]]
  def articles_grouped_by_category
    @articles_grouped_by_category ||= order_articles.
        includes([:article_price, :group_order_articles, :article => :article_category]).
        order('articles.name').
        group_by { |a| a.article.article_category.name }.
        sort { |a, b| a[0] <=> b[0] }
  end

  def articles_sort_by_category
    order_articles.all(:include => [:article], :order => 'articles.name').sort do |a,b|
      a.article.article_category.name <=> b.article.article_category.name
    end
  end

  # Returns the defecit/benefit for the foodcoop
  # Requires a valid invoice, belonging to this order
  #FIXME: Consider order.foodcoop_result
  def profit(options = {})
    markup = options[:without_markup] || false
    if invoice
      groups_sum = markup ? sum(:groups_without_markup) : sum(:groups)
      groups_sum - invoice.net_amount
    end
  end

  # Returns the all round price of a finished order
  # :groups returns the sum of all GroupOrders
  # :clear returns the price without tax, deposit and markup
  # :gross includes tax and deposit. this amount should be equal to suppliers bill
  # :fc, guess what...
  def sum(type = :gross)
    total = 0
    if type == :net || type == :gross || type == :fc
      for oa in order_articles.ordered.includes(:article, :article_price)
        quantity = oa.units * oa.price.unit_quantity
        case type
          when :net
            total += quantity * oa.price.price
          when :gross
            total += quantity * oa.price.gross_price
          when :fc
            total += quantity * oa.price.fc_price
        end
      end
    elsif type == :groups || type == :groups_without_markup
      for go in group_orders.includes(group_order_articles: {order_article: [:article, :article_price]})
        for goa in go.group_order_articles
          case type
            when :groups
              total += goa.result * goa.order_article.price.fc_price(goa.group_order.ordergroup)
            when :groups_without_markup
              total += goa.result * goa.order_article.price.gross_price(goa.group_order.ordergroup)
          end
        end
      end
    end
    total
  end

  # Finishes this order. This will set the order state to "finish" and the end property to the current time.
  # Ignored if the order is already finished.
  # Any supplied options will be passed on to the supplier notifier.
  def finish!(user, options={})
    unless finished?
      Order.transaction do
        # set new order state (needed by notify_order_finished)
        update_attributes!(:state => 'finished', :ends => Time.now, :updated_by => user)

        # Update order_articles. Save the current article_price to keep price consistency
        # Also save results for each group_order_result
        # Clean up
        order_articles.all(:include => :article).each do |oa|
          oa.update_attribute(:article_price, oa.article.article_prices.first)
          oa.group_order_articles.each do |goa|
            goa.save_results!
            # Delete no longer required order-history (group_order_article_quantities) and
            # TODO: Do we need articles, which aren't ordered? (units_to_order == 0 ?)
            #    A: Yes, we do - for redistributing articles when the number of articles
            #       delivered changes, and for statistics on popular articles. Records
            #       with both tolerance and quantity zero can be deleted.
            #goa.group_order_article_quantities.clear
          end
        end

        # Update GroupOrder prices
        group_orders.each(&:update_price!)

        # Stats
        ordergroups.each(&:update_stats!)

        # Notifications
        Resque.enqueue(SupplierNotifier, FoodsoftConfig.scope, 'finished_order', self.id, options)
        Resque.enqueue(UserNotifier, FoodsoftConfig.scope, 'finished_order', self.id)
      end
    end
  end

  # Sets order.status to 'close' and updates all Ordergroup.account_balances
  def close!(user)
    raise I18n.t('orders.model.error_closed') if closed?
    transaction_note = I18n.t('orders.model.notice_close', :name => name,
                              :ends => ends.strftime(I18n.t('date.formats.default')))

    gos = group_orders.all(:include => :ordergroup)       # Fetch group_orders
    gos.each { |group_order| group_order.update_price! }  # Update prices of group_orders

    transaction do                                        # Start updating account balances
      for group_order in gos
        price = group_order.price * -1                    # decrease! account balance
        group_order.ordergroup.add_financial_transaction!(price, transaction_note, user)
      end

      if stockit?                                         # Decreases the quantity of stock_articles
        for oa in order_articles.all(:include => :article)
          oa.update_results!                              # Update units_to_order of order_article
          stock_changes.create! :stock_article => oa.article, :quantity => oa.units_to_order*-1
        end
      end

      self.update_attributes! :state => 'closed', :updated_by => user, :foodcoop_result => profit
    end
  end

  # Close the order directly, without automaticly updating ordergroups account balances
  def close_direct!(user)
    raise I18n.t('orders.model.error_closed') if closed?
    update_attributes! state: 'closed', updated_by: user
  end

  protected

  def starts_before_ends
    return unless ends and starts
    errors.add(:ends, I18n.t('orders.model.error_starts_before_ends')) if ends <= starts
  end
  def starts_and_ends_before_pickup
    return unless pickup
    if ends
      errors.add(:pickup, I18n.t('orders.model.error_ends_before_pickup')) if pickup <= ends
    elsif starts
      errors.add(:pickup, I18n.t('orders.model.error_starts_before_pickup')) if pickup <= starts
    end
  end

  def include_articles
    errors.add(:articles, I18n.t('orders.model.error_nosel')) if article_ids.empty?
  end

  def keep_ordered_articles
    chosen_order_articles = order_articles.find_all_by_article_id(article_ids)
    to_be_removed = order_articles - chosen_order_articles
    to_be_removed_but_ordered = to_be_removed.select { |a| a.quantity > 0 or a.tolerance > 0 }
    unless to_be_removed_but_ordered.empty? or ignore_warnings
      errors.add(:articles, I18n.t(stockit? ? 'orders.model.warning_ordered_stock' : 'orders.model.warning_ordered'))
      @erroneous_article_ids = to_be_removed_but_ordered.map { |a| a.article_id }
    end
  end

  def save_order_articles
    # fetch selected articles
    articles_list = Article.find(article_ids)
    # create new order_articles
    (articles_list - articles).each { |article| order_articles.create(:article => article) }
    # delete old order_articles
    articles.reject { |article| articles_list.include?(article) }.each do |article|
      order_articles.detect { |order_article| order_article.article_id == article.id }.destroy
    end
  end

  private

  # Updates the "price" attribute of GroupOrders or GroupOrderResults
  # This will be either the maximum value of a current order or the actual order value of a finished order.
  def update_price_of_group_orders
    group_orders.each { |group_order| group_order.update_price! }
  end

end

