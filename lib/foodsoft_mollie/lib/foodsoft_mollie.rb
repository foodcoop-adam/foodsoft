require 'Mollie/API/Client'
require 'foodsoft_mollie/engine'

module FoodsoftMollie
  # Enabled when configured, but can still be disabled by +use_mollie+ option.
  def self.enabled?
    FoodsoftConfig[:use_mollie] != false and FoodsoftConfig[:mollie]
  end

  # Compute payment transaction fee.
  #
  # Transaction fee is specified in foodcoop config under +mollie+, +fee+ as a
  # hash of fee per payment method, e.g. as "0.30" for a fixed flat fee, "5%"
  # for a percentage, or "0.30 + 5%" for both. Multiple flat fees and percentages
  # can appear in a single line, so "0.12 + 2% + 0.56 + 3% + 1%" is valid, e.g.
  # when multiple payment providers add different fees.
  #
  # @param amount [Number] Amount payed
  # @param method [String] Payment method used
  # @return [Number] Transaction fee for payment, or +nil+ if no fee details known.
  def self.payment_fee(amount, method)
    spec = FoodsoftConfig[:mollie]['fee'] or return
    unless spec = spec[method]
      Rails.logger.warn "Mollie: transaction fee for method #{method} not configured."
      return
    end
    # parse
    return spec if spec.is_a? Numeric
    spec.split('+').inject(0) do |sum, c|
      sum + (c =~ /^(.*)\s*%\s*$/ ? ($1.to_f/100 * amount.to_f) : c.to_f)
    end
  end
end
