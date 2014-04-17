require 'Mollie/API/Client'
require 'foodsoft_mollie/engine'

module FoodsoftMollie
  # enabled when configured, but can still be disabled by use_mollie option
  def self.enabled?
    FoodsoftConfig[:use_mollie] != false and FoodsoftConfig[:mollie]
  end
end
