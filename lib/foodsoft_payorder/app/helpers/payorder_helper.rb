module PayorderHelper
  def order_payment_status_button(options={})
    return unless @group_orders_sum > 0
    unconfirmed = GroupOrderArticleQuantity.where(group_order_article_id: @goa_by_oa.values.map(&:id)).where(confirmed: [false,nil])
    if unconfirmed.empty?
      link = my_ordergroup_path
      cls = "payment-status-btn #{options[:class]}"
      link_to glyph('ok')+' '+I18n.t('helpers.payorder.paid'), link, {style: 'color: green'}.merge(options).merge({class: cls})
    else
      # TODO use method to get link, and also support external urls
      payment_fee = FoodsoftConfig[:payorder_payment_fee]
      amount = -@ordergroup.get_available_funds + payment_fee.to_f
      return_to = group_order_path(@order_date || :current)
      link = FoodsoftPayorder.payment_link self, amount: amount, fixed: true,
               title: I18n.t('helpers.payorder.payment_prompt'), return_to: return_to
      cls = "payment-status-btn btn btn-primary #{options[:class]}"
      link_to glyph('chevron-right')+' '+I18n.t('helpers.payorder.payment'), link, options.merge({class: cls})
    end
  end
end
