require 'foodsoft_demo/engine'
require 'foodsoft_demo/autologin'
require 'foodsoft_demo/restrict_new_message'

module FoodsoftDemo
  def self.enabled?(what = nil)
    case what
    when :autologin
      FoodsoftConfig[:use_demo_autologin]
    when :restrict_new_message
      FoodsoftConfig[:restrict_new_message]
    when nil
      enabled?(:autologin) or enabled?(:restrict_new_message)
    else
      Rails.logger.warn "FoodsoftDemo.enabled? called with unknown parameter #{what}"
    end
  end
end
