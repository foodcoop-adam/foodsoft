require_relative '../spec_helper'

describe ArticlePrice do
  let (:article_price) { create(:article) }
  let (:price_markup) { FoodsoftConfig[:price_markup] }

  table = [
    # Foodsoft Configuration                        Price                  Expected result
    # price_markup, price_markup_tax, deposit_tax,  price, deposit, tax,   gross_price, tax_price, fc_price, fc_tax_price, fc_markup_price
    [ 3, false, true,                               10,    0,       6,     10.60,       0.60,      10.92,    0.60,         0.32 ],
    [ 5, false, true,                               10,    0,       6,     10.60,       0.60,      11.13,    0.60,         0.53 ],
    [ 5, false, true,                               10,    0,       9,     10.90,       0.90,      11.45,    0.90,         0.55 ],

    [ 5, false, true,                               10,    1,       6,     11.66,       0.66,      12.19,    0.66,         0.53 ],
    [ 5, false, false,                              10,    1,       6,     11.60,       0.60,      12.13,    0.60,         0.53 ],

    [ 3, true,  true,                               10,    0,       6,     10.60,       0.60,      10.92,    0.62,         0.30 ],
    [ 5, true,  true,                               10,    0,       6,     10.60,       0.60,      11.13,    0.63,         0.50 ],
    
    [ 5, true,  true,                               10,    1,       6,     11.66,       0.66,      12.19,    0.69,         0.50 ],
    [ 5, true,  false,                              10,    1,       6,     11.60,       0.60,      12.13,    0.63,         0.50 ]
  ]

  table.each_index do |i|
    row = table[i]

    it "computes prices correctly (row #{i})" do
      FoodsoftConfig.config[:price_markup] = row[0]
      FoodsoftConfig.config[:price_markup_tax] = row[1]
      FoodsoftConfig.config[:deposit_tax] = row[2]

      article_price.price = row[3]
      article_price.deposit = row[4]
      article_price.tax = row[5]

      expect(article_price.gross_price).to be_within(0.005).of row[6]
      expect(article_price.tax_price).to be_within(0.005).of row[7]
      expect(article_price.fc_price).to be_within(0.005).of row[8]
      expect(article_price.fc_tax_price).to be_within(0.005).of row[9]
      expect(article_price.fc_markup_price).to be_within(0.005).of row[10]
    end
  end

end
