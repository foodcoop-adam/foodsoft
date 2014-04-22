# A sample Gemfile
source "https://rubygems.org"
#ruby "1.9.3"

gem "rails", '~> 3.2.9'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'less-rails'
  gem 'uglifier', '>= 1.0.3'
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', platforms: :ruby
end

gem 'jquery-rails'
gem 'select2-rails', '>= 3.4.0'
gem 'bootstrap-datepicker-rails'
gem 'date_time_attribute'
gem 'rails-assets-listjs', '0.2.0.beta.4' # remember to maintain list.*.js plugins and template engines on update
gem 'i18n-js', git: 'git://github.com/fnando/i18n-js.git' # to avoid US-ASCII js.erb error
gem 'rails-i18n'
gem 'world-flags', '~> 0.6.4'

gem 'mysql2'
gem 'prawn'
gem 'haml-rails'
gem 'kaminari'
gem 'simple_form'
gem 'client_side_validations'
gem 'client_side_validations-simple_form'
gem 'inherited_resources'
gem 'localize_input', git: "git://github.com/bennibu/localize_input.git"
gem 'daemons'
gem 'twitter-bootstrap-rails'
gem 'simple-navigation'
gem 'simple-navigation-bootstrap'
gem 'meta_search'
gem 'acts_as_tree'
gem "rails-settings-cached", "0.2.4"
gem 'resque'
gem 'whenever', require: false # For defining cronjobs, see config/schedule.rb
gem 'ruby-units'
gem 'ice_cube', github: 'greenriver/ice_cube', branch: 'issues/50-from_ical' # fork until seejohnrun/ice_cube#50 is merged
gem 'charlock_holmes'
gem 'attribute_normalizer'
gem 'version_info'

# we use the git version of acts_as_versioned, and need to include it in this Gemfile
#gem 'acts_as_versioned', git: 'git://github.com/technoweenie/acts_as_versioned.git'
#gem 'foodsoft_wiki', path: 'lib/foodsoft_wiki'
gem 'foodsoft_messages', path: 'lib/foodsoft_messages'

gem 'foodsoft_mollie', path: 'lib/foodsoft_mollie'
gem 'foodsoft_adyen', path: 'lib/foodsoft_adyen'
gem 'foodsoft_signup', path: 'lib/foodsoft_signup'
gem 'foodsoft_current_orders', path: 'lib/foodsoft_current_orders'
#gem 'foodsoft_vokomokum', path: 'lib/foodsoft_vokomokum'
#gem 'foodsoft_protect_shared', path: 'lib/foodsoft_protect_shared'
#gem 'foodsoft_userinfo', path: 'lib/foodsoft_userinfo'
gem 'foodsoft_mailall', path: 'lib/foodsoft_mailall'
gem 'foodsoft_payorder', path: 'lib/foodsoft_payorder'
#gem 'foodsoft_uservoice', path: 'lib/foodsoft_uservoice'
gem 'foodsoft_orderdoc', path: 'lib/foodsoft_orderdoc'
#gem 'foodsoft_demo', path: 'lib/foodsoft_demo'
#gem 'foodsoft_multishared', path: 'lib/foodsoft_multishared'

group :production do
  gem 'exception_notification'
end

group :development do
  gem 'sqlite3'
  gem 'mailcatcher'
  
  # Better error output
  gem 'better_errors'
  gem 'binding_of_caller'
  # gem "rails-i18n-debug"
  # chrome debugging extension https://github.com/dejan/rails_panel
  gem 'meta_request'
  
  # Get infos when not using proper eager loading
  gem 'bullet'

  # Hide assets requests in log
  gem 'quiet_assets'
  
  # Deploy with Capistrano
  gem 'capistrano', '~> 3.2.0', require: false
  gem 'capistrano-rvm', require: false
  gem 'capistrano-bundler', '>= 1.1.0', require: false
  gem 'capistrano-rails', require: false
  # Avoid having content-length warnings
  gem 'thin'
end

group :development, :test do
  gem 'ruby-prof', require: false
end

group :test do
  gem 'rspec-rails'
  gem 'factory_girl_rails', '~> 4.0'
  gem 'faker'
  gem 'capybara'
  # webkit and poltergeist don't seem to work yet
  gem 'selenium-webdriver'
  gem 'database_cleaner'
  gem 'connection_pool'
  # need to include rspec components before i18n-spec or rake fails in test environment
  gem 'rspec-core'
  gem 'rspec-expectations'
  gem 'rspec-rerun'
  gem 'i18n-spec'
  # code coverage
  gem 'simplecov', require: false
  gem 'coveralls', require: false
end
