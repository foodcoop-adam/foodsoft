module AdyenPinHelper

  # link to pin payment redirect - with optional token for mobile
  def new_payment_link(ordergroup, options={}, &block)
    options = {data: {ajax: false}}.merge(options)
    link_opts = {ordergroup_id: ordergroup.id}
    %w{token mobile_app}.each {|o| link_opts[o] = params[o] if params[o] }
    link_to new_payments_adyen_pin_path(link_opts), options, &block
  end

end
