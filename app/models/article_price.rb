#
# Article price computations.
#
# Foodsoft has several configuration options regarding tax rules.
# `deposit_tax` sets whether the deposit needs to be taxed,
# `price_markup_tax` indicates whether the markup needs to be taxed.
#
# These are the formulas, where `T%` is the VAT percentage, and `M%`
# is the markup percentage. Parts between [] are only taken into
# account when `deposit_tax` is `true`.
#
#     tax = net * T% [+ deposit * T%]
#     gross = net + deposit + tax = net * (1 + T%) + deposit [+ deposit * T%]
#
# When `price_markup_tax` is `true`:
#
#     fc_markup = net * M%
#     fc_tax = tax + fc_markup * T%
#            = net*T% [+deposit*T%] + net*M% * T%
#            = net * T% * (1+M%) [+ deposit * T%]
#
# and when `price_markup_tax` is `false`:
#
#     fc_markup = gross * M% = net * (1 + T%) * M%
#     fc_tax = tax = net * T% [+ deposit * T%]
#
# And then, for both after expansion (expand separately, has same answer):
#
#     fc = net + deposit + fc_tax + fc_markup
#        = gross + net * (1 + T%) * M%
#        = net * (1 + T%) * (1 + M%) + deposit [+ deposit * T%]
#
class ArticlePrice < ActiveRecord::Base

  belongs_to :article
  has_many :order_articles

  validates_presence_of :price, :tax, :deposit, :unit_quantity
  validates_numericality_of :price, :greater_than_or_equal_to => 0
  validates_numericality_of :unit_quantity, :greater_than => 0
  validates_numericality_of :deposit, :tax

  localize_input_of :price, :tax, :deposit

  def tax_price(group=nil)
    ArticlePrice.tax_price(self, group)
  end

  def gross_price(group=nil)
    ArticlePrice.gross_price(self, group)
  end

  def fc_price(group=nil)
    ArticlePrice.fc_price(self, group)
  end

  def fc_tax_price(group=nil)
    ArticlePrice.fc_tax_price(self, group)
  end

  def fc_markup_price(group=nil)
    ArticlePrice.fc_markup_price(self, group)
  end

  # Amount going to tax (excluding tax over markup)
  def self.tax_price(price, group=nil)
    tax_price = price.price * price.tax/100
    tax_price += price.deposit * price.tax/100 if FoodsoftConfig[:deposit_tax]
    return tax_price
  end

  # The financial gross, net plus tax and deposit.
  def self.gross_price(price, group=nil)
    gross_price = price.price * (price.tax/100 + 1)
    gross_price += price.deposit
    gross_price += price.deposit * price.tax/100 if FoodsoftConfig[:deposit_tax]
    return gross_price
  end

  # The price for the foodcoop-member.
  def self.fc_price(price, group=nil)
    markup_pct = ArticlePrice.markup_pct(group)
    fc_price = price.price * (price.tax/100 + 1) * (markup_pct/100 + 1)
    fc_price += price.deposit
    fc_price += price.deposit * price.tax/100 if FoodsoftConfig[:deposit_tax]
    # @todo we don't compute any markup for the deposit, at this moment (used to in the past, though!)
    return fc_price
  end

  # The amount of tax in the price for the foodcoop-member (incl. any taxes over the markup).
  def self.fc_tax_price(price, group=nil)
    fc_tax_price = ArticlePrice.tax_price(price, group)
    fc_tax_price += price.price * ArticlePrice.markup_pct(group)/100 * price.tax/100 if FoodsoftConfig[:price_markup_tax]
    return fc_tax_price
  end

  # The markup of the price
  def self.fc_markup_price(price, group=nil)
    markup_pct = ArticlePrice.markup_pct(group)
    fc_markup_price = price.price * markup_pct/100
    fc_markup_price += price.price * price.tax/100 * markup_pct/100 unless FoodsoftConfig[:price_markup_tax]
    return fc_markup_price
  end

  # The markup percentage for the foodcoop-member.
  def self.markup_pct(group=nil)
    if group.present?
      group.markup_pct
    elsif list = FoodsoftConfig[:price_markup_list]
      list[FoodsoftConfig[:price_markup]]['markup'].to_f
    else
      FoodsoftConfig[:price_markup].to_f
    end
  end
end

