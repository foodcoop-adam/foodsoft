module FoodsoftVokomokum
  # @return [Boolean] Whether payment reminders need to be sent (most probably)
  def self.need_to_send_payment_reminders?
    !Order.finished_not_closed.any? && Order.closed.where(payment_reminders_sent_at: nil).any?
  end
end
