# Foodsoft 3.3.5-adam
(29 aug 2014)

* Improvements in the receive screen
* Make distribute screen layout a little clearer
* Redesign "Fax PDF" and call it to "Order PDF" from now on
* Handle (ajax) errors better
* Allow to enter amount in unit or kg/g/l/... in distribute screen
* Allow to configure how ordergroup margin is shown on member profile
* Allow foodcoops to specify custom CSS for styling
* Allow to set page-break options for articles and groups PDFs separately
* Bugfix: do not show deleted members in CSV download

# Foodsoft 3.3.4-adam
(10 Jun 2014)

* Allow donations with membership fee payment
* Allow to show extra text on membership fee payment page
* Improve performance of certain queries
* Only show navigation items that are accessible
* New view for all transactions
* Send emails to members in their own language
* Make CSV export more compatible with Microsoft Excel (using ; as separator)
* Allow different foodcoop markup levels for ordergroups
* Hide insignificant zeroes for percentage (no more 6.000%, but 6%)
* Allow to use a small number of variables in configurable texts
* Allow to synchronize all articles of a shared supplier
* Give partially unused articles an orange colour in view order
* Add page footer
* Bugfix: export orderdoc in same file format as original (requires reinstalling the macro)
* Bugfix: protected signup (with key) didn't work
* Bugfix: fix member ordering on Internet Explorer (clicks weren't registered on IE11+)

# Foodsoft 3.3.3-adam
(17 Apr 2014)

* Article uploads support Microsoft Excel and OpenOffice.org file formats
* Most other plugins can now be enabled/disabled on a per-foodcoop basis
* Vokomokum plugin now updates totals at the dry ordering system
* New orderdoc plugin: suppliers can get original spreadsheet filled in with order
* Bugfix: membership fee was not debited
* Bugfix: add some missing translations

# Foodsoft 3.3.2-adam
(04 Apr 2014)

* Foodsoft messages can now be enabled/disabled using a plugin (upstream)
* Admins can (bulk) invite new members
* The signup plugin can now be enabled/disabled on a per-foodcoop basis
* Make foodsoft work with some older browsers
* Several small fixes and enhancements

# Foodsoft 3.3.1-adam
(20 Mar 2014)

* Improved order close dialog
* Allow to send mail to supplier when closing an order
* Add PDF configuration options for font-size, paper-size and page breaks
* Use the same form for invitations and signup
* It's now possible to specify a pickup-day for orders
* Article synchronisation now understands all units (50ml, 21gr, etc.)
* Avoid word-wrap when showing currency

# Foodsoft 3.3.0-adam
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

# Foodsoft 3.2.1-adam
(24 Feb 2014; tagged in retrospect)

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
