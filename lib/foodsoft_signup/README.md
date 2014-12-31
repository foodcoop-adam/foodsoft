FoodsoftSignup
==============

This project adds support for a signup form to
[foodsoft](https://github.com/foodcoops/foodsoft).
At `/:foodcoop/login/signup` there is a new form where prospective members can
fill in their details and create an account (with an ordergroup). This allows
them to login to foodsoft, but only when their account is approved by an
administrator can they access all areas of the site. Typically, one would
restrict placing an order to approved accounts only.

**Note:** this plugin uses [ImageMagick](http://imagemagick.org/) for anti-spam
[CAPTCHA](https://en.wikipedia.org/wiki/CAPTCHA)s on the signup form. You'll
need to `apt-get install libmagickwand-dev` (or equivalent on your platform)
when enabling this plugin.

**Note:** this plugin uses [deface](http://rubygems.org/gems/deface); you may
want to [precompile templates](https://github.com/spree/deface/blob/master/README.markdown#production--precompiling)
in production for performance reasons.


Configuration
-------------
This plugin is configured in the foodcoop configuration in foodsoft's
"config/app\_config.yml":
```yaml
  # Membership fee substracted from balance when a new ordergroup is created
  membership_fee: 35
  # The membership fee is fixed by default. If you'd like members to be able
  # to enter a larger amount, uncomment the following, and members will be able
  # to enter a larger amount than the membership_fee on payment.
  #membership_fee_donate: true

  # enable to to allow public signup
  use_signup: true

  # disable signup when there are this many ordergroups or more (unlimited by default)
  #signup_ordergroup_limit: 25

  # Array of which pages are accesible to ordergroups that are not approved.
  # Values are controller names (`pages`) or actions combined with controller
  # names (`pages#show`). If not set, the default is:
  # `home login sessions signup feedback pages#show pages#all group_orders#archive`
  # When you're using a payment plugin for approval, add its controller here.
  unapproved_allow_access:
  - home
  - login
  - sessions
  - signup
  - feedback
  - pages#show
  - pages#all
  - group_orders#archive

  # In case you'd like to have protected signup form, and allow members who
  # signup to order directly, you can enable the following. This effectively
  # disables approval, and requires a key in the signup url:
  #   https://foodcoop.test/f/login/signup?key=verySeCrEt123
  #unapproved_allow_access: '*'
  #signup_key: 'verySeCrEt123'

  # Message to show when ordergroup is not yet approved. If not set, a concise
  # default message will be shown.
  #ordergroup_approval_msg:
  #  Your membership still needs to be approved. Please transfer €35 to account
  #  12345678 "FC Test" in Berlin, mentioning "membership fee" and your
  #  username. After up to three days, your account will be activated, and you
  #  will be able to order here.

  # Payment link to show when ordergroup is not yet approved. When this is set,
  # "%{link}" will be substituted with the link in the approval message.
  # When starting with http: or https:, this is considered to be a full url; else 
  # a Ruby name that will be evaluated on the controller.
  #ordergroup_approval_payment: new_payments_mollie_path

  # You can customize the fields shown on the membership payment form.
  #ordergroup_approval_payment_label: Membership fee
  #ordergroup_approval_payment_title: Pay your membership
  #ordergroup_approval_payment_text:
  #  A membership contribution is needed so that we can do the initial investments.
  #  If you really like this initiative, please feel free to donate more by adjusting
  #  the amount.

  # By default ordergroup approval is enabled when signup is enabled; in case
  # you'd like to control this independently, set it to true or false.
  #use_approval: signup

```
