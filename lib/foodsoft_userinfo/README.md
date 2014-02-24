= FoodsoftUserinfo

Simple userinfo endpoint for using foodsoft authentication with external
systems. Loosely modeled on
[OpenID Connect Lite's idea](http://openid.net/specs/openid-connect-lite-1_0-08.html#userinfo).

`https://foodcoop.test/:foodcoop/login/userinfo` will return JSON data, user
information when the user is logged in, an error when not.

Also includes the possibility to add a `return_to` parameter to Foodsoft's
login page, which is redirected to when the user has a valid session. Only
configured urls are allows, as specified in `config/app_config.yml`:

   ```yaml
   # Any url starting with one of those is allowed as a return_to parameter to login
   userinfo_return_urls:
   - https://app.foodcoop.test/forum
   ```
