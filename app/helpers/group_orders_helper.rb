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

  # Return css class names for order result table

  def order_article_class_name(quantity, tolerance, result)
    if (quantity + tolerance > 0)
      result > 0 ? 'success' : 'failed'
    else
      'ignored'
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
    missing = [unit_quantity - quantity_left - tolerance_left, 0].max

    pct = ->(x){ (100*x/unit_quantity).to_i }

    content_tag(:div, class: "progress #{'progress-reverse' if quantity_left==0}") do
      content_tag(:div, quantity_left, class: "bar", style: "width: #{pct[quantity_left]}%") +
      content_tag(:div, tolerance_left, class: "bar bar-light#{'er bar-inset' if quantity_left==0}", style: "width: #{pct[tolerance_left]}%") +
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
