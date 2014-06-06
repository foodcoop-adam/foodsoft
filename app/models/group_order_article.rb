  # A GroupOrderArticle stores the sum of how many items of an OrderArticle are ordered as part of a GroupOrder.
# The chronologically order of the Ordergroup - activity are stored in GroupOrderArticleQuantity
#
class GroupOrderArticle < ActiveRecord::Base

  belongs_to :group_order
  belongs_to :order_article
  has_many   :group_order_article_quantities, :dependent => :destroy

  validates_presence_of :group_order, :order_article
  validates_inclusion_of :quantity, :in => 0..99
  validates_inclusion_of :result, :in => 0..99, :allow_nil => true
  validates_inclusion_of :tolerance, :in => 0..99
  validates_uniqueness_of :order_article_id, :scope => :group_order_id    # just once an article per group order

  scope :ordered, -> { includes(:group_order => :ordergroup).order(:groups => :name) }

  localize_input_of :result

  # Setter used in group_order_article#new
  # We have to create an group_order, if the ordergroup wasn't involved in the order yet
  def ordergroup_id=(id)
    self.group_order = GroupOrder.find_or_initialize_by_order_id_and_ordergroup_id(order_article.order_id, id)
  end

  def ordergroup_id
    group_order.try(:ordergroup_id)
  end

  # Updates the quantity/tolerance for this GroupOrderArticle by updating both GroupOrderArticle properties 
  # and the associated GroupOrderArticleQuantities chronologically.
  # 
  # See description of the ordering algorithm in the general application documentation for details.
  def update_quantities(quantity, tolerance)
    logger.debug "GroupOrderArticle[#{id}].update_quantities(#{quantity}, #{tolerance})"
    logger.debug "Current quantity = #{self.quantity}, tolerance = #{self.tolerance}"

    # When quantity and tolerance are zero, we don't serve any purpose
    if quantity == 0 and tolerance == 0
      logger.debug "Self-destructing since requested quantity and tolerance are zero"
      destroy
      return
    end

    # can't build GroupOrderArticleQuantity associations when we have no id
    save! if new_record?

    # Get quantities ordered with the newest item first.
    quantities = group_order_article_quantities.find(:all, :order => 'created_on desc')
    logger.debug "GroupOrderArticleQuantity items found: #{quantities.size}"

    if quantities.size == 0
      # There is no GroupOrderArticleQuantity item yet, just insert with desired quantities...
      logger.debug "No quantities entry at all, inserting a new one with the desired quantities"
      quantities.push GroupOrderArticleQuantity.new(:group_order_article => self, :quantity => quantity, :tolerance => tolerance)
      self.quantity, self.tolerance = quantity, tolerance
    else
      # Decrease quantity/tolerance if necessary by going through the existing items and decreasing their values...
      i = 0
      while (i < quantities.size && (quantity < self.quantity || tolerance < self.tolerance))
        logger.debug "Need to decrease quantities for GroupOrderArticleQuantity[#{quantities[i].id}]"
        if (quantity < self.quantity && quantities[i].quantity > 0)
          delta = self.quantity - quantity
          delta = (delta > quantities[i].quantity ? quantities[i].quantity : delta)
          logger.debug "Decreasing quantity by #{delta}"
          quantities[i].quantity -= delta
          self.quantity -= delta
        end
        if (tolerance < self.tolerance && quantities[i].tolerance > 0)
          delta = self.tolerance - tolerance
          delta = (delta > quantities[i].tolerance ? quantities[i].tolerance : delta)
          logger.debug "Decreasing tolerance by #{delta}"
          quantities[i].tolerance -= delta
          self.tolerance -= delta
        end
        i += 1
      end
      # If there is at least one increased value: insert a new GroupOrderArticleQuantity object
      if (quantity > self.quantity || tolerance > self.tolerance)
        logger.debug "Inserting a new GroupOrderArticleQuantity"
        delta_quantity = (quantity > self.quantity ? quantity - self.quantity : 0)
        delta_tolerance = (tolerance > self.tolerance ? tolerance - self.tolerance : 0)
        quantities.unshift GroupOrderArticleQuantity.new(
            :group_order_article => self,
            :quantity => delta_quantity,
            :tolerance => delta_tolerance
        )
        # Recalc totals:
        self.quantity += delta_quantity
        self.tolerance += delta_tolerance
      end
    end

    # Check if something went terribly wrong and quantites have not been adjusted as desired.
    if (self.quantity != quantity || self.tolerance != tolerance)
      raise 'Invalid state: unable to update GroupOrderArticle/-Quantities to desired quantities!'
    end

    # Remove zero-only items.
    quantities.reject! {|q| q.quantity == 0 && q.tolerance == 0}
    # Merge quantity if within throttling time
    update_quantities_merge quantities

    # Save
    transaction do
      quantities.each {|i| i.save!}
      self.group_order_article_quantities = quantities
      save!
    end
  end

  # Determines how many items of this article the Ordergroup receives.
  # Returns a hash with three keys: :quantity / :tolerance / :total
  # 
  # See description of the ordering algorithm in the general application documentation for details.
  def calculate_result(total = nil)
    # return memoized result unless a total is given
    return @calculate_result if total.nil? and not @calculate_result.nil?

    quantity = tolerance = total_quantity = 0

    # Get total
    if not total.nil?
      logger.debug "<#{order_article.article.name}> => #{total} (given)"
    elsif order_article.article.is_a?(StockArticle)
      total = order_article.article.quantity
      logger.debug "<#{order_article.article.name}> (stock) => #{total}"
    else
      total = order_article.units_to_order * order_article.price.unit_quantity
      logger.debug "<#{order_article.article.name}> units_to_order #{order_article.units_to_order} => #{total}"
    end

    if total > 0
      # In total there are enough units ordered. Now check the individual result for the ordergroup (group_order).
      #
      # Get all GroupOrderArticleQuantities for this OrderArticle...
      #
      order_quantities = get_quantities_for_order_article.all
      logger.debug "GroupOrderArticleQuantity records found: #{order_quantities.size}"

      # Determine quantities to be ordered...
      order_quantities.each do |goaq|
        q = [goaq.quantity, total - total_quantity].min
        total_quantity += q
        if goaq.group_order_article_id == self.id
          logger.debug "increasing quantity by #{q}"
          quantity += q
        end
        break if total_quantity >= total
      end

      # Determine tolerance to be ordered...
      if total_quantity < total
        logger.debug "determining additional items to be ordered from tolerance"
        order_quantities.each do |goaq|
          q = [goaq.tolerance, total - total_quantity].min
          total_quantity += q
          if goaq.group_order_article_id == self.id
            logger.debug "increasing tolerance by #{q}"
            tolerance += q
          end
          break if total_quantity >= total
        end
      end

      logger.debug "determined quantity/tolerance/total: #{quantity} / #{tolerance} / #{quantity + tolerance}"
    end

    # memoize result unless a total is given
    r = {:quantity => quantity, :tolerance => tolerance, :total => quantity + tolerance}
    @calculate_result = r if total.nil?
    r
  end

  # Returns order result.
  #
  # This is either calculated on the fly, or fetched from result attribute,
  # which is is set when finishing the order.
  # @see #calculate_result
  # @param type [Symbol] which result: +total+, +quantity+ or +tolerance+.
  # @return [Number] Order result
  def result(type = :total)
    self[:result] || calculate_result[type]
  end

  # This is used for automatic distribution, e.g., in order.finish! or when receiving orders
  def save_results!(article_total = nil)
    new_result = calculate_result(article_total)[:total]
    self.update_attribute(:result_computed, new_result)
    self.update_attribute(:result, new_result)
  end

  # Returns total price for this individual article
  # Until the order is finished this will be the maximum price or
  # the minimum price depending on configuration. When the order is finished it
  # will be the value depending of the article results.
  def total_price(order_article = self.order_article, quantity = self.quantity, tolerance = self.tolerance)
    total_prices(order_article, quantity, tolerance)[:price]
  end
  def total_prices(order_article = self.order_article, quantity = self.quantity, tolerance = self.tolerance)
    price = order_article.price
    amount = if order_article.order.open?
               if FoodsoftConfig[:tolerance_is_costly]
                 (quantity + tolerance)
               else
                 quantity
               end
             else
               result
             end
    {
      net_price:   amount * price.price,
      gross_price: amount * price.gross_price(group_order.ordergroup),
      deposit:     amount * price.deposit,
      price:       amount * price.fc_price(group_order.ordergroup),
      tax_price:   amount * price.tax_price(group_order.ordergroup)
    }
  end

  # Check if the result deviates from the result_computed
  def result_manually_changed?
    result != result_computed unless result.nil?
  end

  # (separate method so that it can be overridden by plugin)
  def get_quantities_for_order_article
    GroupOrderArticleQuantity.where(group_order_article_id: order_article.group_order_article_ids).order('created_on')
  end

  # Merge quantity if within throttling time.
  # (separate method so that it can be overridden by plugin)
  def update_quantities_merge(quantities)
    quantity_time_delta = (FoodsoftConfig[:quantity_time_delta_server] || 30).to_i
    if quantity_time_delta > 0
      if quantities[0] and quantities[1] and quantities.second.created_on > quantity_time_delta.seconds.ago
        logger.debug "Merging new GroupOrderArticleQuantity with most recent"
        merging = quantities.shift
        quantities[0].quantity += merging.quantity
        quantities[0].tolerance += merging.tolerance
      end
    end
    quantities
  end

end
