Foodsoft
=========
[![Build Status](https://travis-ci.org/foodcoop-adam/foodsoft.svg?branch=beta)](https://travis-ci.org/foodcoop-adam/foodsoft)
[![Coverage Status](https://coveralls.io/repos/foodcoop-adam/foodsoft/badge.png?branch=master)](https://coveralls.io/r/foodcoop-adam/foodsoft?branch=master)
[![Docs Status](http://inch-ci.org/github/foodcoop-adam/foodsoft.png?branch=master)](http://inch-ci.org/github/foodcoop-adam/foodsoft)
[![Code Climate](https://codeclimate.com/github/foodcoop-adam/foodsoft.png)](https://codeclimate.com/github/foodcoop-adam/foodsoft)
[![Dependency Status](https://gemnasium.com/foodcoop-adam/foodsoft.png)](https://gemnasium.com/foodcoop-adam/foodsoft)
[![Issue board](http://b.repl.ca/v1/issue-board-78bdf2.png)](https://waffle.io/foodcoop-adam/foodsoft)
[![Documentation](http://b.repl.ca/v1/yard-docs-blue.png)](http://rubydoc.info/github/foodcoop-adam/foodsoft/frames)

Web-based software to manage a non-profit food coop (product catalog, ordering, accounting, job scheduling).

A food cooperative is a group of people that buy food from suppliers of their own choosing. A collective do-it-yourself supermarket. Members  order their products online and collect them on a specified day. And all put in a bit of work to make that possible. Foodsoft facilitates the process.

This branch contains the version used by a couple of Dutch food cooperatives, most importantly
[Foodcoop Amsterdam](http://www.foodcoopamsterdam.nl), [Vokomokum](http://www.vokomokum.nl),
[FoodCoopNoord](http://www.foodcoopnoord.nl) and [Voedlink](http://www.voedlink.nl).

It is based on [foodcoops/foodsoft](https://github.com/foodcoops/foodsoft) (which we call _upstream_).
While new features are still being added, ultimately this is all meant to be integrated back into upstream
([#163](https://github.com/foodcoop-adam/foodsoft/issues/163)).

If you're a food coop considering to use foodsoft, you're welcome to [contact us](dev-voko-contact@willem.engen.nl). Or look at the [wiki page for foodcoops](https://github.com/foodcoops/foodsoft/wiki/For-foodcoops). You can [read documentation](http://foodcoop-adam.github.io/) to get an impression of the software. When you'd like to experiment with or develop foodsoft, you can read [how to set it up](doc/SETUP_DEVELOPMENT.md) on your own computer.

More information about using this software and contributing can be found on [our wiki](https://github.com/foodcoop-adam/foodsoft/wiki), as wel [foodsoft's wiki](https://github.com/foodcoops/foodsoft/wiki).


Notes specific to this fork
---------------------------

* This fork has enabled some plugins that aren't upstream. To make migration easier, we have included database migrations for these plugins.  As a developer, that means: when you add a migration to an enabled plugin, please use `rake railties:install:migrations` and commit to install those in `db/migrate` as well.

* The main branch is _beta_. This is based on _master_ (which is deprecated), which in turn was forked from a Rails 3 version of foodcoops/foodsoft. Many upstream changes were merged in, and many other changes as well. Beta was initially meant as a testing ground for a redesigned member ordering interface, but ended up being used in production. There is some technical debt here. While there has been some work in _feature/rails4-adam_ to migrate this to Rails 4, the idea is now to merge back changes to upstream instead.

* You may need to disable MySQL's strict mode by running:

      echo "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));" | mysql

See also the wiki page [foodcoop adaptations](https://github.com/foodcoop-adam/foodsoft/wiki/Foodcoop-adaptations).


Developing
----------

Get foodsoft [running locally](doc/SETUP_DEVELOPMENT.md),
then visit our [Developing Guidelines](https://github.com/foodcoops/foodsoft/wiki/Developing-Guidelines)
page on the wiki.

When developing a new feature, please consider to make it work on upstream first, then backport it here.
That helps keeping the focus on integrating everything back into upstream.


Deploying
---------

Setup foodsoft to [run in production](doc/SETUP_PRODUCTION.md),
and automate [deployment](doc/DEPLOYMENT.md). This section is
very much a work in progress.


License
-------

GPL version 3 or later, please see [LICENSE](LICENSE.md) for the full text.
Some bundled third-party components have [other licenses](vendor/README.md).

