# This plain ruby class should handle all user notifications, called by various models
class SupplierNotifier
  @queue = :foodsoft_notifier

  # Resque style method to perform every class method defined here
  def self.perform(foodcoop, method_name, *args)
    FoodsoftConfig.select_foodcoop(foodcoop) if FoodsoftConfig[:multi_coop_install]
    self.send method_name, *args
  end

  def self.finished_order(order_id, options={})
    options.symbolize_keys!
    order = Order.find(order_id)
    unless to = order.order_send_emails and not to.empty?
      Rails.logger.info "Order #{order_id} finished, not sending because there is no recipient."
      return
    end
    # only send mail when there are articles to order
    unless order.can_send == true
      Rails.logger.info "Order #{order_id} finished, not sending because: #{order.can_send}"
      return
    end
    # send mail to supplier if order_howto is an email address
    Mailer.order_result_supplier(order, to, options).deliver
  end
end
