module GroupOrdersHelper
  def data_to_js(order, oa, goa)
    row = [oa.id,oa.article.fc_price, oa.article.unit_quantity, goa.total_price, oa.quantity - goa.quantity, oa.tolerance - goa.tolerance, goa.result(:quantity), (@order.stockit? ? oa.article.quantity_available : 0)]
    "addData(#{row.join(', ')});"
  end

  def link_to_ordering(order, options = {})
    path = if group_order = order.group_order(current_user.ordergroup)
             edit_group_order_path(group_order, :order_id => order.id)
           else
             new_group_order_path(:order_id => order.id)
           end
    link_to order.name, path, options
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
end
