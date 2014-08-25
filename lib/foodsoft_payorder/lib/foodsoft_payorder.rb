require 'deface'
require 'foodsoft_payorder/engine'
require 'foodsoft_payorder/update_group_order_articles'
require 'foodsoft_payorder/update_payment_status_header'
require 'foodsoft_payorder/cleanup_on_order_finish'

module FoodsoftPayorder
  def self.enabled?(what = nil)
    case what
    when nil
      FoodsoftConfig[:use_payorder]
    when :remove_unpaid
      enabled? and FoodsoftConfig[:payorder_remove_unpaid]
    else
      Rails.logger.warn "FoodsoftPayorder.enabled? called with unknown parameter #{what}"
      false
    end
  end

  # include the option return_to to come back after payment
  def self.payment_link(c, options={})
    unless FoodsoftConfig[:payorder_payment].blank?
      c.send FoodsoftConfig[:payorder_payment], options
    else
      '#please_configure:payorder_payment'
    end
  end
end
