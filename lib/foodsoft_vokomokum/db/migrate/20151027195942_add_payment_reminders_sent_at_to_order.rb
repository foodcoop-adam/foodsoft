class AddPaymentRemindersSentAtToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :payment_reminders_sent_at, :datetime
  end
end
