FoodsoftPayorder
================

Allows members to pay their order online right after ordering.

You probably want to load a payment provider plugin, and point to it
in the foodcoop configuration (see below).

Configuration
-------------
This plugin is configured in the foodcoop configuration in foodsoft's
"config/app\_config.yml":
```
  # Enable to add a payment button on the current order overview, and only
  # order articles that members have paid (like a shopping cart).
  use_payorder: true

  # Payment link.
  # When starting with http: or https:, this is considered to be a full url; else 
  # a Ruby name that will be evaluated on the controller.
  payorder_payment: new_payments_adyen_hpp_path

  # Payment fee.
  # This will be added to all payorder transactions. The real payment fee may
  # still be different, so make sure to choose a default level that is sufficient.
  #payorder_payment_fee: 1.20

  # When the member would only need to pay a couple of cents to get its items, it
  # is better to charge the article and pay the difference next ordering round.
  # These are the maximum 'grace' couple of cents.
  #payorder_grace_price: 0.10

  # Unpaid articles remain present, but have a zero result. To remove them from
  # the system when the order closes, uncomment the following line. (default `false`)
  #payorder_remove_unpaid: true
```
