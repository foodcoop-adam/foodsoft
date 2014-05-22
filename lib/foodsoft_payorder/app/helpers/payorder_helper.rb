module PayorderHelper
  def order_payment_status_button(options={})
    return unless @group_orders_sum > 0
    if @ordergroup.get_available_funds >= 0
      link = my_ordergroup_path
      cls = "payment-status-btn #{options[:class]}"
      link_to glyph('ok')+' '+I18n.t('helpers.payorder.paid'), link, {style: 'color: green'}.merge(options).merge({class: cls})
    else
      # TODO use method to get link, and also support external urls
      amount = -@ordergroup.get_available_funds
      return_to = group_order_path(@order_date || :current)
      link = FoodsoftPayorder.payment_link self, amount: amount, fixed: true,
               title: I18n.t('helpers.payorder.payment_prompt'), return_to: return_to
      cls = "payment-status-btn btn btn-primary #{options[:class]}"
      link_to glyph('chevron-right')+' '+I18n.t('helpers.payorder.payment'), link, options.merge({class: cls})
    end
  end
end
