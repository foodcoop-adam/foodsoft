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


Implementation notes
--------------------

This plugin makes quite deep modifications to Foodsoft and the ordering process. It may
be helpful to explain in some detail how the different numbers are interpreted when this
plugin is used.

**GroupOrderArticleQuantity** tells when a member has entered a quantity for an article.
This is extended with a `financial_transaction`. When computing order totals, only records
with a (paid) transaction are counted. (And when `payorder_remove_unpaid` is set, all other
records are even deleted upon closing the order.)

**GroupOrderArticle** quantity and tolerance are those ordered by the member. Result
includes only paid articles (or what they actually received after the order is finished).
See `#calculate_result`.

**GroupOrder** totals include paid and unpaid articles. Payorder uses
`Ordergroup#get_available_funds` to find out how much a member needs to pay, which is
computed by `GroupOrderArticle#total_prices`.

**OrderArticle** totals only include paid articles, also when the order is open. This
allows foodcoops to monitor ordering progress.

Note that, while the order is open, `GroupOrderArticle#result` only includes paid articles,
whereas `GroupOrderArticle#total_prices` includes both paid and unpaid.
