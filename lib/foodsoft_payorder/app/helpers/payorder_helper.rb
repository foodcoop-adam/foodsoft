module PayorderHelper
  def order_payment_status_button(options={})
    if @ordergroup.get_available_funds >= 0
      link = my_ordergroup_path
      link_to glyph('ok')+' '+'paid', link, {style: 'color: green', class: 'payment-status-btn'}.merge(options)
    else
      # TODO use method to get link, and also support external urls
      amount = -@ordergroup.get_available_funds
      link = FoodsoftPayorder.payment_link self, amount: amount, title: 'Pay for your current orders', fixed: true
      link_to glyph('chevron-right')+' '+'Payment', link, {class: 'btn btn-primary payment-status-btn'}.merge(options)
    end
  end
end
