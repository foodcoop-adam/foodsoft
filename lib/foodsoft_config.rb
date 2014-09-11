# Foodcoop-specific configuration.
#
# This is loaded from +config/app_config.yml+, which contains a root
# key for each environment (plus an optional +defaults+ key). When using
# the multicoops feature (+multicoops+ is set to +true+ for the environment),
# each foodcoop has its own key.
#
# In addition to the configuration file, values can be overridden in the database
# using {RailsSettings::CachedSettings} as +foodcoop.<foodcoop_scope>.**+.
#
class FoodsoftConfig

  # @!attribute scope
  #   Returns the current foodcoop scope for the multicoops feature, otherwise
  #   the value of the foodcoop configuration key +default_scope+ is used.
  #   @return [String] The current foodcoop scope.
  mattr_accessor :scope
  # @!attribute config
  #   Returns a {ActiveSupport::HashWithIndifferentAccess Hash} with the current
  #   scope's configuration from the configuration file. Note that this does not
  #   include values that were changed in the database.
  #   @return [ActiveSupport::HashWithIndifferentAccess] Current configuration from configuration file.
  mattr_accessor :config

  # Configuration file location.
  #   Taken from environment variable +FOODSOFT_APP_CONFIG+,
  #   or else +config/app_config.yml+.
  APP_CONFIG_FILE = ENV['FOODSOFT_APP_CONFIG'] || 'config/app_config.yml'
  # Rails.logger isn't ready yet - and we don't want to litter rspec invocation with this msg
  puts "-> Loading app configuration from #{APP_CONFIG_FILE}" unless defined? RSpec
  # Loaded configuration
  APP_CONFIG = ActiveSupport::HashWithIndifferentAccess.new(
    YAML.load(File.read(File.expand_path(APP_CONFIG_FILE, Rails.root)))
  )

  class << self

    def init
      # Load initial config from development or production
      set_config Rails.env
      # Overwrite scope to have a better namescope than 'production'
      self.scope = config[:default_scope] or raise "No default_scope is set"
      # Set defaults for backward-compatibility
      set_missing
    end

    # Set config and database connection for specific foodcoop.
    #
    # Only needed in multi coop mode.
    # @param foodcoop [String, Symbol] Foodcoop to select.
    def select_foodcoop(foodcoop)
      set_config foodcoop
      setup_database
    end

    # Return configuration value for the currently selected foodcoop.
    #
    # First tries to read configuration from the database (cached),
    # then from the configuration files.
    #
    #     FoodsoftConfig[:name] # => 'FC Test'
    #
    # To avoid errors when the database is not yet setup (when loading
    # the initial database schema), cached settings are only being read
    # when the settings table exists.
    #
    # @param key [String, Symbol]
    # @return [Object] Value of the key.
    def [](key)
      if RailsSettings::CachedSettings.table_exists? and allowed_key?(key)
        value = RailsSettings::CachedSettings["foodcoop.#{self.scope}.#{key}"]
        value = config[key] if value.nil?
        value
      else
        config[key]
      end
    end

    # Store configuration in the database.
    #
    # If value is equal to what's defined in the configuration file, remove key from the database.
    # @param key [String, Symbol] Key
    # @param value [Object] Value
    # @return [Boolean] Whether storing succeeded (fails when key is not allowed to be set in database).
    def []=(key, value)
      return false unless allowed_key?(key)
      # try to figure out type ...
      value = case value
                when 'true' then true
                when 'false' then false
                when /^[-+0-9]+$/ then value.to_i
                when /^[-+0-9.]+([eE][-+0-9]+)?$/ then value.to_f
                when '' then nil
                else value
              end
      # then update database
      if config[key] == value or (config[key].nil? and value == false)
        # delete (ok if it was already deleted)
        begin
          RailsSettings::CachedSettings.destroy "foodcoop.#{self.scope}.#{key}"
        rescue RailsSettings::Settings::SettingNotFound
        end
      else
        # or store
        RailsSettings::CachedSettings["foodcoop.#{self.scope}.#{key}"] = value
      end
      return true
    end

    # @return [Array<String>] Configuration keys that are set (either in +app_config.yml+ or database).
    def keys
      keys = RailsSettings::CachedSettings.get_all("foodcoop.#{self.scope}.").try(:keys) || []
      keys.map! {|k| k.gsub /^foodcoop\.#{self.scope}\./, ''}
      keys += config.keys
      keys.map(&:to_s).uniq
    end

    # Loop through each foodcoop and executes the given block after setup config and database
    def each_coop
      if config[:multi_coop_install]
        APP_CONFIG.keys.reject { |coop| coop =~ /^(default|development|test|production)$/ }.each do |coop|
          select_foodcoop coop
          yield coop
        end
      else
        yield config[:default_scope]
      end
    end

    # @return [Boolean] Whether this key may be set in the database
    def allowed_key?(key)
      # fast check for keys without nesting
      return !self.config[:protected].keys.include?(key.to_s)
      # @todo allow to check nested keys as well
    end

    private

    def set_config(foodcoop)
      raise "No config for this environment (#{foodcoop}) available!" if APP_CONFIG[foodcoop].nil?
      self.config = APP_CONFIG[foodcoop]
      self.scope = foodcoop
      set_missing
    end

    def setup_database
      database_config = ActiveRecord::Base.configurations[Rails.env]
      database_config = database_config.merge(config[:database]) if config[:database].present?
      ActiveRecord::Base.establish_connection(database_config)
    end

    # When new options are introduced, put backward-compatible defaults here, so that
    # configuration files that haven't been updated, still work as they did. This also
    # makes sure that the configuration editor picks up the defaults.
    def set_missing
      config.replace({
        use_nick: true,
        use_wiki: true,
        use_messages: true,
        use_paymanual: true,
        use_apple_points: true,
        # English is the default language, and this makes it show up as default.
        default_locale: 'en',
        foodsoft_url: 'https://github.com/foodcoops/foodsoft',
        # The following keys cannot be set by foodcoops themselves.
        protected: {
          multi_coop_install: nil,
          default_scope: nil,
          notification: nil,
          shared_lists: nil,
          protected: nil,
          database: nil
        }
      }.merge(config))
    end

    # reload original configuration file, e.g. in between tests
    def reload!(filename = APP_CONFIG_FILE)
      APP_CONFIG.clear.merge! YAML.load(File.read(File.expand_path(filename, Rails.root)))
      init
    end

    # return list of foodcoop scopes
    def scopes
      APP_CONFIG.keys.reject { |scope| scope =~ /^(default|development|test|production)$/ }
    end

  end
end
