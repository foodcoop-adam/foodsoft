# Foodsoft foodcoop-adam 3.3.0
(10 Mar 2014)

* Hide deleted ordergroups in "Check member orders"
* Allow foodcoop to configure a default language (e.g. for the signup form)
* Remove invoices menu item, which wasn't used anyway
* Allow new members to specify a different email address on invitations
* Cleanup email footer
* Allow to synchronise article from shared database using a button in the edit article dialog
* Add fax spreadsheet (csv) to order
* Make installing foodsoft work better when installing on a suburi
* Make sorting orders work again in the orders overview screen
* [signup plugin] Allow the signup form to be protected by a key in the url
* [mailall plugin] Fix mailall plugin breaking admin user search
* [mollie plugin] Leep payment details on return page when payment fails

# Foodsoft foodcoop-adam 3.2.0 (post-factum release)
(24 Feb 2014)

This is the first official foodcoop-adam release. There are too many changes to
document here, but the gist is that we
* removed many elements that we don't use from the user-interface;
* made a task-based navigation menu;
* added online payment features (mollie and adyen plugins);
* made the financial transactions screen more details, pre-filling the amount, providing often-used notes;
* use a more fancy listbox (select2);
* allow to lists in pages of 500 items;
* redesigned the member ordering screen;
* add url to articles;
* allow members to signup and pay a membership fee (signup plugin);
* allow to work with all current orders at once (current\_orders plugin);
* allow to edit article result from orders screen;
* allow to integrate other software with foodsoft login (userinfo plugin);
* add support for uservoice (uservoice plugin);
* allow to configure a default language, e.g. for the signup form.

# Foodsoft 3.3.0
(24 Feb 2014)

* New improvements the stock section.
* New receive screen for redistributing articles when the order is closed. Members with orders and finance permission are now able to change the amount received, and redistribute that over the members.
* Amounts received by ordergroups can now be edited directly in the ordergroup and article list.
* Redesigned article edit dialog.
* Do not offer to add deleted articles in the balancing screen.
* Work nicely with browsers remembering passwords.
* Add RSS feed for wiki updates (navigate to Wiki -> All pages).
* Clearer error message when a wiki page contains a syntax error.
* More graceful response on access denied errors.
* Touch devices are now better supported.
* Added some missing translations.
* Other small fixes.

# Foodsoft 3.2.0
(16 December 2013)

It's been a year since the previous release. Much has changed. Big changes have been:
* Translations to English, Dutch and French.
* Improved usability of delivery creation.
* The possibility to extend foodsoft with plugins (the wiki is now optional).
* Article search in the ordering screen.
* Foodcoops can choose to use full names and emails instead of nicknames.
* Foodcoops that don't use prepaid can set their minimum ordergroup balance below zero.
* Group and article PDFs now show articles ordered but not received in grey.
* Upgrade to Rails 3.

When you upgrade, be sure to review `config/app_config.yml.SAMPLE`. When you're running multiple foodcoops from a single installation, check your rake invocations as the syntax is now: `rake multicoops:run TASK=db:migrate`.

# Foodsoft 3.1.1
(20 July 2012)
