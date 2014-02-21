# This plain ruby class should handle all user notifications, called by various models
class SupplierNotifier
  @queue = :foodsoft_notifier

  # Resque style method to perform every class method defined here
  def self.perform(foodcoop, method_name, *args)
    FoodsoftConfig.select_foodcoop(foodcoop) if FoodsoftConfig[:multi_coop_install]
    self.send method_name, *args
  end

  def self.finished_order(order_id)
    order = Order.find(order_id)
    to = FoodsoftConfig[:send_order_on_finish] or return
    # only send mail when there are articles to order
    unless order.can_send == true
      Rails.logger.info "Order #{order_id} finished, not sending because: #{order.can_send}"
      return
    end
    # gather email addresses to send to
    to.map! do |a|
      if a == '%{supplier}'
        unless order.supplier.order_send_email
          Rails.logger.warn "Order #{order_id} finished but order_send_email missing, no email sent to supplier"
        end
        order.supplier.order_send_email
      elsif a == '%{contact.email}'
        FoodsoftConfig[:contact]['email']
      else
        a
      end
    end.compact!
    # send mail to supplier if order_howto is an email address
    Mailer.order_result_supplier(order, to).deliver unless to.empty?
  end
end
