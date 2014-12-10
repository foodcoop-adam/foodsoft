FoodsoftVokomokum
=================

This plugin integrates
[foodsoft](https://github.com/foodcoops/foodsoft)
with the ordering system of [Vokomokum](http://www.vokomokum.nl/), a Foodcoop
based in Amsterdam, The Netherlands. It features:
* login using an existing session cookie,
* automatic user creation on successful login, and
* uploading of ordergroup totals to the Vokomokum system (in progress).


Configuration
-------------
This plugin is configured in the foodcoop configuration in foodsoft's
"config/app\_config.yml":

   ```yaml
   # Vokomokum members website url
   vokomokum_members_url: http://members.vokomokum.nl/

   # Vokomokum order website url
   vokomokum_order_url: http://order.vokomokum.nl/

   # Vokomokum cookie domain (for single-logout)
   vokomokum_cookie_domain: .vokomokum.nl

   # To access the Vokomokum system with a session from a different ip address,
   # authentication is needed. Make sure they match Vokomokum configuration.
   # This is used for both the members and order system.
   vokomokum_client_id: external_app
   vokomokum_client_secret: ze_zekrit_123
   ```

There are no default values, so you need to set them. This is intentional.


Login with session cookie
-------------------------

When running foodsoft on the same domain, the session cookie can be shared.
Foodsoft will pick that up and validate it with the Vokomokum member system.

To use Foodsoft on a different domain, a form is needed to pass on the session
cookie. All that's needed is a web form that POSTs to the `login/vokomokum`
path, setting the `Mem` parameter to the session cookie. E.g.:

   ```html
   <form action='https://order.foodsoft.test/f/login/vokomokum' method='post'>
     <input type='hidden' name='Mem' value='"0123456789!userid_type:int"'>
     <input type='submit' value='Fresh ordering'>
   </form>
   ```

Additional notes
----------------

Since Vokomokum uses member ids extensively, the user id of foodsoft is
synchronised with that. This also means that any users available to foodsoft
but not to Vokomokum are created with an offset of 20000.  If the number of
Vokomokum users would ever cross that boundary, this needs to be increased.

