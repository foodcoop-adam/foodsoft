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
  # Payment link.
  # When starting with http: or https:, this is considered to be a full url; else 
  # a Ruby name that will be evaluated on the controller.
  payorder_payment: new_payments_adyen_hpp_path
```
