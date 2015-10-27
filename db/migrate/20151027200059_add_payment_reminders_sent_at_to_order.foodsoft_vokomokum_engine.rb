# This migration comes from foodsoft_vokomokum_engine (originally 20151027195942)
class AddPaymentRemindersSentAtToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :payment_reminders_sent_at, :datetime
  end
end
