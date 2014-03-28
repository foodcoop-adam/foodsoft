module PayorderHelper
  def order_payment_status_button(options={})
    return unless @group_orders_sum > 0
    if @ordergroup.get_available_funds >= 0
      link = my_ordergroup_path
      cls = "payment-status-btn #{options[:class]}"
      link_to glyph('ok')+' '+'paid', link, {style: 'color: green'}.merge(options).merge({class: cls})
    else
      # TODO use method to get link, and also support external urls
      amount = -@ordergroup.get_available_funds
      return_to = group_order_path(@order_date || :current)
      link = FoodsoftPayorder.payment_link self, amount: amount, title: 'Pay for your current orders', fixed: true, return_to: return_to
      cls = "payment-status-btn btn btn-primary #{options[:class]}"
      link_to glyph('chevron-right')+' '+'Payment', link, options.merge({class: cls})
    end
  end
end
