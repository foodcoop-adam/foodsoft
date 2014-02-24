FoodsoftMollie
==============

This project adds support for iDEAL payments using Mollie to Foodsoft.

* Make sure the gem is uncommented in foodsoft's `Gemfile`
* Enter your Mollie account details in `config/app_config.yml`

```yaml
  # Mollie payment settings
  mollie:
    partner_id: 1234567
    profile_key: '89ABCDEF'
    test_mode: true          # set to false on production
```

To initiate a payment, redirect to `new_payments_mollie_path` at `/:foodcoop/payments/mollie/new`.
The following url parameters are recognised:
* ''amount'' - default amount to charge (optional)
* ''fixed'' - when "true", the amount cannot be changed (optional)
* ''title'' - page title (optional)
* ''label'' - label for amount (optional)

