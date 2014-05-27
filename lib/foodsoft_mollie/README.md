FoodsoftMollie
==============

This project adds support for iDEAL payments using Mollie to Foodsoft.

* Make sure the gem is uncommented in foodsoft's `Gemfile`
* Enter your Mollie account details in `config/app_config.yml`

```yaml
  # Mollie payment settings
  mollie:
    # API key for account: 1234567, website profile: FooInc
    api_key: test_1234567890abcdef1234567890abcd
    # Transaction fee per payment method, fixed rate and/or percentage.
    #   This is substracted from the amount actually credited to the ordergroup's account balance.
    fee:
      # example fees from May 2014 incl. 21% VAT (verify before using!)
      ideal: 1.20
      banktransfer: 0.30
      paysafecard: 15%
      creditcard: 3.39% + 0.05
      paypal: 0.18 + 0.35 + 3.4%
      mistercash: 2.18% + 0.30
      bitcoin: 0.30
```

At this moment, the transaction fee is not used. But the idea is that
the transaction fee will be added on each payment when set; it is not set by default,
meaning that the foodcoop will pay any transaction costs (out of the margin).

To initiate a payment, redirect to `new_payments_mollie_path` at `/:foodcoop/payments/mollie/new`.
The following url parameters are recognised:
* ''amount'' - default amount to charge (optional)
* ''fixed'' - when "true", the amount cannot be changed (optional)
* ''title'' - page title (optional)
* ''label'' - label for amount (optional)
* ''min'' - minimum amount accepted (optional)

This plugin also introduces the foodcoop config option `use_mollie`, which can
be set to `false` to disable this plugin's functionality. May be useful in
multicoop deployments.
