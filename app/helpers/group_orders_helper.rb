module GroupOrdersHelper

  include ArticlesHelper # for article_info_icon

  def data_to_js(ordering_data)
    ordering_data[:order_articles].map { |id, data|
      [id, data[:price], data[:unit], data[:total_price], data[:others_quantity], data[:others_tolerance], data[:used_quantity], data[:quantity_available]]
    }.map { |row|
      "addData(#{row.join(', ')});"
    }.join("\n")
  end

  # Returns a link to the page where a group_order can be edited.
  # If the option :show is true, the link is for showing the group_order.
  def link_to_ordering(order, options = {}, &block)
    path = if options[:show]
             group_order_path(:current)
           else
             edit_group_order_path(:current, q: {order_id_eq: order.id})
           end
    options.delete(:show)
    name = block_given? ? capture(&block) : order.name
    path ? link_to(name, path, options) : name
  end

  # @return [String] CSS class name for order result table
  def order_article_class_name(quantity, tolerance, result)
    if (quantity + tolerance > 0)
      result > 0 ? 'success' : 'failed'
    else
      'ignored'
    end
  end

  # @param n [Number] Requested quantity (or tolerance)
  # @param n_result [Number] Resulting quantity (or tolerance)
  # @return [String] CSS class name for group_order_article based on result
  # @see OrdersHelper#order_article_class
  def group_order_article_class_name(n, n_result)
    if n > 0
      if n_result == 0
        'unused member'
      elsif n_result < n
        'partused member'
      else
        'used member'
      end
    end
  end

  def get_order_results(order_article, group_order_id)
    goa = order_article.group_order_articles.detect { |goa| goa.group_order_id == group_order_id }
    quantity, tolerance, result, sub_total = if goa.present?
      [goa.quantity, goa.tolerance, goa.result, goa.total_price(order_article)]
    else
      [0, 0, 0, 0]
    end

    {group_order_article: goa, quantity: quantity, tolerance: tolerance, result: result, sub_total: sub_total}
  end

  def orders_status_line(orders)
    if (ends_open = orders.select(&:open?)).present?
      if ends_open = (ends_open.map(&:ends).compact.minmax)[0]
        return FoodsoftDateUtil.distance_of_time_in_words ends_open
      else
        return I18n.t('orders.state.open')
      end
    end
    if end_finished = orders.select(&:finished?).map(&:ends).max
      return I18n.t('helpers.group_orders.finished_since', when: format_date(end_finished))
    end
    if end_closed = orders.select(&:closed?).map(&:ends).max
      return I18n.t('helpers.group_orders.closed_since', when: format_date(end_closed))
    end
  end

  def orders_title(orders)
    if orders.select(&:open?).any?
      I18n.t('group_orders.my_current_order')
    elsif orders.select(&:finished?).any?
      I18n.t('group_orders.my_last_order')
    else
      I18n.t('group_orders.my_previous_order')
    end
  end

  def final_unit_bar(order_article)
    unit_quantity = order_article.price.unit_quantity
    amount_to_order = order_article.units_to_order * unit_quantity

    quantity_left = [order_article.quantity - amount_to_order, 0].max
    tolerance_left = order_article.tolerance - [amount_to_order - order_article.quantity, 0].max
    tolerance_left_clip = [tolerance_left, unit_quantity].min
    missing = [unit_quantity - quantity_left - tolerance_left, 0].max

    spct = ->(x){ "width: #{(100*x/unit_quantity).to_i}%" }

    tolerance_left_txt = "#{tolerance_left_clip}#{"+" if tolerance_left > tolerance_left_clip}"
    clslight = quantity_left==0 ? "bar-lighter" : "bar-light"
    content_tag(:div, class: "progress #{'progress-reverse' if quantity_left==0}") do
      content_tag(:div, quantity_left, class: "bar", style: spct[quantity_left]) +
      content_tag(:div, tolerance_left_txt, class: "bar #{clslight}", style: spct[tolerance_left_clip]) +
      content_tag(:span, missing, class: "text")
    end
  end

  # @param span [Number] Number of cells to span
  # @param tag [Symbol] Tag to use for the cell (+td+ or +th+)
  # @return [String] Cell spanning a number of columns, or +nil+ if +span+ is zero.
  def cell_span(span, tag=:th)
    content_tag(tag, nil, colspan: span) if span and span > 0
  end
end
