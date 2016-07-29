FoodsoftVokomokum
=================

This plugin integrates
[foodsoft](https://github.com/foodcoops/foodsoft)
with the ordering system of [Vokomokum](http://www.vokomokum.nl/), a Foodcoop
based in Amsterdam, The Netherlands. It features:
* login using an existing session cookie,
* automatic user creation on successful login,
* sending order totals to the Vokomokum members system when settling,
* synchronizing workgroup memberships from the members system, and
*


Configuration
-------------
This plugin is configured in the foodcoop configuration in foodsoft's
"config/app\_config.yml":

   ```yaml
   # Vokomokum members website url
   vokomokum_members_url: http://members.vokomokum.nl/

   # Vokomokum cookie domain (for single-logout)
   vokomokum_cookie_domain: .vokomokum.nl

   # To access the Vokomokum system with a session from a different ip address,
   # authentication is needed. Make sure they match Vokomokum configuration.
   # This is used for both the members and order system.
   vokomokum_client_id: external_app
   vokomokum_client_secret: ze_zekrit_123
   ```

There are no default values, so you need to set them. This is intentional.


Running a local members instance
---------------------------------

To test the Vokomokum plugin, an instance of the Vokomokum members system
is needed. This is most easily done using a [Docker](http://docker.com/) image:

    docker pull nhoening/vokomokum-members
    docker run --name=vkmkm -d -p 6543:6543 nhoening/vokomokum-members

Then set `vokomokum_members_url: http://localhost:6543/` in your `app\_config.yml`.

Because it's running at a different port, auto-login won't get back to Foodsoft.
After logging into the members system, look at the `Mem` and `Key` cookies,
and add these as GET parameters to Foodsoft's `/f/login/vokomokum` url.

There are default accounts _admin@vokomokum.nl_, _peter@gmail.com_ and
_hans@gmail.com_ all with password _notsecret_
(see [mksqlitedb.py](https://app.assembla.com/spaces/vokomokum/git/source/master/members/scripts/mksqlitedb.py)).


Login with session cookie
-------------------------

When running foodsoft on the same domain, the session cookie can be shared.
Foodsoft will pick that up and validate it with the Vokomokum member system.

To use Foodsoft on a different domain, the authentication cookie can also
be passed in the url. For example, redirecting to

    https://order.foodsoft.test/f/login/vokomokum?Mem=123&Key=abcdefghIjk-jias

Would login user 123 in Foodsoft with the specified session key. For more
security, this is also accepted as a POSTed form body.


Workgroups
----------

A member's workgroup memberships are updated at each login. This requires the
workgroup names in Foodsoft to be exactly equal to the workgroup names in the
Vokomokum member system (including case). Please make sure to rename the
workgroups in Foodsoft too when changing them in the members system.

There is one exception: workgroup with id 1 (typically the Admin workgroup)
is managed in Foodsoft, to make sure that if something goes wrong there are
people who can repair it. It would be better not to delete it.


Additional notes
----------------

Since Vokomokum uses member ids extensively, the user id of foodsoft is
synchronised with that. This also means that any users available to foodsoft
but not to Vokomokum are created with an offset of 20000.  If the number of
Vokomokum users would ever cross that boundary, this needs to be increased.

Perhaps this offset is dropped in the future, since the member id is now
included in the ordergroup name as well. For now, we use the id of the first
member of an ordergroup.
