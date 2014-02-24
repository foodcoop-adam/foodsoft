= FoodsoftAdyen

This project adds support for Adyen payments to Foodsoft.

* Make sure the gem is uncommented in foodsoft's `Gemfile`
* When using the signup plugin
  * add `payments/adyen_notifications` to `unapproved_allow_access` in `config/app_config.yml`
  * add `payments/adyen_hpp` to the same list
  * set `ordergroup_approval_payment` to `new_payments_adyen_hpp_path` in the foodcoop config if you want to approve membership with an online payment


== Foodsoft configuration

This plugin is configured in the foodcoop configuration in foodsoft's
"config/app\_config.yml":
```
  adyen:
    # ISO currency code - http://www.currency-iso.org/en/home/tables/table-a1.html
    currency: EUR

    # Merchant account
    merchant_account: OtterlabsPOS
    # HMAC Key for test or production (it takes time to propagate if you change this)
    hmac_key: 1234567890abcdefghijklmnopqrstuvwxyz
    # Payment skin to use
    skin_code: 1z2Y2x3W

    # Notification authentication. Anyone who knows this can credit foodsoft accounts.
    notify_username: somewhat_s3cret_identifier
    notify_password: tRuLySeCrEtpAssWoRdth@1No0ne2hoULdKn0wR3@Lly
```


== Adyen configuration

=== Notifications

The Adyen notifications API is used to credit accounts. That means that you
need to enable notifications the Adyen customer area:

* Log into https://ca-live.adyen.com/
* Choose your merchant account
* Go to `Settings` then `Notifications`
* Enter the following settings:
  * URL: `https://your.foodsoft.host/:foodcoop/payments/adyen/notify`
  * Active: `yes`
  * Method: `HTTP POST (parameters)`
  * Populate SOAP header: `no`
* In `Authentication`, specify the user and password you set earlier in
  your environment configuration in `config.foodsoft_adyen.notify_username` and
  `config.foodsoft_adyen.notify_password`. It anyone knows these, they can
  credit accounts, so do make sure to use a long password that's impossible to
  remember.
* Press `Save Settings`

Now use the option to test a notification (below in the same Adyen CA screen).
Check your rails log file to see if the notification was received properly.

=== Skin

To use hosted payment pages (online payments), you need to create a skin in the
Adyen customer area. The following fields are relevant for foodsoft:

* `Result URL for Test`: `https://your.foodsoft.host/:foodcoop/payments/adyen/hpp/result`
* `HMAC Key for Test`: same as foodcoop config `adyen.hmac_key`. This is a random
  string of characters. Note that when you change this, it may take a while to propagate
  in the Adyen systems.


== PIN payment flow

PIN payments are done using the mobile Adyen app. At the time of writing, this is
somewhat new, and the app may not be fully stabilised yet; but it should be usable.

The flow is like this:

1. In `/f/payments/adyen/pin`, an ordergroup is selected.
2. This redirects to the Adyen app on the mobile platform. The query string in the
     redirect is used to pass amount and description.
3. The Adyen app processes the payment.
4. The Adyen app redirects to the foodsoft callback page, with a `result` parameter
     indicating success or failure.
5. The foodsoft user-interface shows whether it succeeded or not. No financial
     transaction is added, however, since that is taken care of by the
     Adyen HTTP POST notification. This also makes sure that no url tampering
     on the browser can be used to credit accounts without real payments.
6. Shortly after, that might take a couple of minutes, Adyen will call the
     notification URL, where the user's account can be updated.

