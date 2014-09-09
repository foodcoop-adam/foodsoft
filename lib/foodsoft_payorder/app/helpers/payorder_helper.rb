module PayorderHelper
  def order_payment_status_button(options={})
    return unless @group_orders_sum > 0
    if order_needs? :payment
      # TODO use method to get link, and also support external urls
      payment_fee = FoodsoftConfig[:payorder_payment_fee]
      amount = -@ordergroup.get_available_funds + payment_fee.to_f
      return_to = group_order_path(@order_date || :current)
      pay_link = FoodsoftPayorder.payment_link self, amount: amount, fixed: true,
               title: I18n.t('helpers.payorder.payment_prompt'), return_to: return_to
      cls = "payment-status-btn btn btn-primary #{options[:class]}"
      # @todo use button_to with Rails 4+ instead of this workaround (below too)
      form_tag confirm_group_orders_path(return_to: pay_link) do
        button_tag glyph('chevron-right')+' '+I18n.t('helpers.payorder.payment'), options.merge({class: cls})
      end
    elsif order_needs? :confirmation
      cls = "payment-status-btn btn btn-primary #{options[:class]}"
      form_tag confirm_group_orders_path do
        button_tag glyph('chevron-right')+' '+I18n.t('helpers.payorder.confirm'), options.merge({class: cls})
      end
    else
      link = my_ordergroup_path
      cls = "payment-status-btn #{options[:class]}"
      link_to glyph('ok')+' '+I18n.t('helpers.payorder.paid'), link, {style: 'color: green'}.merge(options).merge({class: cls})
    end
  end

  # @param types [Symbol, Array<Symbol>] Which actions to check: +payment+ or +confirmation+; or +nil+ for any.
  # @return [Boolean] Whether the member order needs user action to go through
  def order_needs?(what=nil)
    @group_orders_sum > 0 or return false
    what = [what] unless what.nil? or what.is_a? Array
    if what.nil? or what.include? :payment
      return true if @ordergroup.get_available_funds < 0
    end
    if what.nil? or what.include? :confirmation
      goaqs = GroupOrderArticleQuantity.where(group_order_article_id: @goa_by_oa.values.map(&:id))
      return true if goaqs.where(confirmed: false).any?
    end
    return false
  end
end
