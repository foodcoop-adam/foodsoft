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
    if (ends_open = orders.select(&:open?).map(&:ends).minmax)[0]
      if ends_open[0] == ends_open[1]
        return "#{time_ago_in_words(ends_open[0])} remaining"
      else
        return "#{time_ago_in_words(ends_open[1])} to #{time_ago_in_words(ends_open[0])} remaining"
      end
    end
    if end_finished = orders.select(&:finished?).map(&:ends).max
      return "closed since #{format_date(end_finished)}"
    end
    if end_closed = orders.select(&:closed?).map(&:ends).max
      return "settled since #{format_date(end_closed)}"
    end
  end
end
