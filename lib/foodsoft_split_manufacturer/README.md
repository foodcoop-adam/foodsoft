FoodsoftSplitManufacturer
=========================

Allow operations on orders to be split by manufacturer on some places.
Right now, this means that article PDFs can be downloaded by manufacturer.

Configuration
-------------
This plugin is configured in the foodcoop configuration in foodsoft's
"config/app\_config.yml":
```
  # Whether to show some operations by manufacturer instead of order.
  use_split_manufacturer: true
```

Please note that this plugin be must listed after `foodsoft_multishared`, when
enabled, so that all user-interface overrides work.
