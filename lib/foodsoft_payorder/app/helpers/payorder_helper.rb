module PayorderHelper
  def order_payment_status_button(has_paid, options={})
    if has_paid
      content_tag :span, glyph('ok')+' '+'paid', style: 'color: green'
    else
      # TODO use method to get link, and also support external urls
      amount = -@ordergroup.get_available_funds
      link = self.send(FoodsoftConfig[:ordergroup_approval_payment], amount: amount, title: 'Pay for your current orders', fixed: true)
      link_to glyph('chevron-right')+' '+'Payment', link, options
    end
  end
end
