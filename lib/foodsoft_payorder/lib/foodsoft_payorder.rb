require 'deface'
require 'foodsoft_payorder/engine'
require 'foodsoft_payorder/update_group_order_articles'
require 'foodsoft_payorder/update_payment_status_header'

module FoodsoftPayorder
  def self.enabled?
    FoodsoftConfig[:use_payorder]
  end

  def self.payment_link(c, options={})
    unless FoodsoftConfig[:payorder_payment].blank?
      c.send(FoodsoftConfig[:payorder_payment], options.merge(return_to: c.request.fullpath))
    else
      '#please_configure:payorder_payment'
    end
  end
end
