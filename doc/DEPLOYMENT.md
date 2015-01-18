Deployment
=========

Setup
-----

1. Initialise your [Capistrano](http://capistranorb.com/) setup

      ```sh
      bundle exec cap install
      cp config/deploy.rb.SAMPLE config/deploy.rb
      ```

   Uncomment the rails, bundler and rvm lines in `Capfile`.

2. Adapt your configuration in `config/deploy.rb`.

   For `order.foodcoop.nl`, uncomment the `bundler_` lines to share system gems.


3. Setup configuration for foodsoft instance(s) in `config/deploy/*.rb`. This could look like

     ```
     # config/deploy/main.rb
     set :suburi,     'main'
     set :stage,      'production'

     server fetch(:domain), user: fetch(:user), roles: [:web, :app, :resque, :db]
     ```

   Each deployment would have its own `suburi`, this example would be deployed
   in `/www/apps/foodsoft_main`.


Deploy
------

On your first deploy you should run (choose either staging or production)

    bundle exec cap main deploy:check

The first argument to `cap` points to a file in `config/deploy`, in this case
it would be `config/deploy/main.rb`.

This may fail the very first time, which is ok, because there is no configuration yet.
On your server, there is a directory `shared/config` for each installation,
which contains the configuration. Create `database.yml`, `app_config.yml` and
`initializers/secret_token.rb` and try again.  (See
`lib/capistrano/tasks/deploy_initial.cap` for a way to automate this.)

Deploy main

    bundle exec cap main deploy deploy:restart

