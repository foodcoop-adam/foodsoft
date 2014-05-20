FoodsoftMultishared
===================

Allows multiple foodcoops to participate in each other's orders when sharing a
single database. Uses the multicoops functionality.

Foodcoop options in `config/app_config.yml`:
```yaml
  # If defined, this foodcoop scope has access to *all* foodcoops records.
  #master_scope: central

  # Foodcoop takes part in all orders of the foodcoop(s) specified here.
  #join_scope: central

  # Set this to true to hide the foodcoop from foodcoop lists, like the
  # central signup list introduced by the multishared plugin.
  #hidden: true

  # When showing this foodcoop in a list of foodcoops, this is added
  # as a short description. Empty by default.
  #list_desc: for yuppies and greenies, every last Friday of the month
  # Text to show in foodcoop list search box
  #list_search_placeholder: Search city or name...

  # Introduction text on group selection signup page.
  #multishared_signup_text: "Select which foodcoop you'd like to join:"
  # Map zoom level, or 'auto' to fit all (default is auto)
  #multishared_signup_zoom: auto

  # Uncomment to show address as default subtitle in foodcoop instances.
  #use_subname_address: true

  # When enabled, users can change the foodcoop of their ordergroup (from
  # profile). It is not possible to join hidden foodcoops. When set to `login`,
  # the user will be redirected to the page to choose a foodcoop (e.g., when
  # a foodcoop stops, and members are suggested to join another one).
  #select_scope: true
  # When select_scope is `login`, this message, when present, is shown on
  # top of the foodcoop selection page after logging in. By default it is
  # not set and no message is shown.
  #select_scope_text: Please select a new foodcoop to join:
```

When you're using the messages plugin, be sure to enable that before enabling
this plugin (the messages migration needs to be run before multishared).

