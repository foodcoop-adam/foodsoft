require_relative '../spec_helper'

describe GroupOrder do
  let(:go)  { create :group_order, order: order }
  let(:order) { create :order, article_count: 2 }

  # the following two tests are currently disabled - https://github.com/foodcoops/foodsoft/issues/158

  #it 'needs an order' do
  #  expect(build :group_order, order: nil).to be_invalid
  #end

  #it 'needs an ordergroup' do
  #  expect(build :group_order, ordergroup: nil).to be_invalid
  #end

  it 'has zero price initially' do
    expect(go.price).to eq(0)
  end


  describe 'computes total' do
    let(:go) { create :group_order, order: order }
    let(:oa) { order.order_articles.first }
    let(:goa) { create :group_order_article, group_order: go, order_article: oa }
    let(:oa2) { order.order_articles.second }
    let(:goa2) { create :group_order_article, group_order: go, order_article: oa2 }

    it 'fc price' do
      n = rand(5) * oa.price.unit_quantity
      goa.update_quantities n, 0
      go.update_price!
      expect(go.price).to eq oa.price.fc_price*n
    end

    it 'gross price' do
      n = rand(5) * oa.price.unit_quantity
      goa.update_quantities n, 0
      go.update_price!
      expect(go.gross_price).to eq oa.price.gross_price*n
    end
  end


  describe 'with ordergroup price markup' do
    let(:admin) { create :admin }
    let(:oa) { order.order_articles.first }
    let(:go2) { create :group_order, order: order }
    let(:goa) { create :group_order_article, group_order: go, order_article: oa }
    let(:goa2) { create :group_order_article, group_order: go2, order_article: oa }

    before do
      FoodsoftConfig.config[:price_markup] = 'default'
      FoodsoftConfig.config[:price_markup_list] = {'low' => {'markup' => 2.5}, 'default' => {'markup' => 5}, 'high' => {'markup' => 20}}
      Ordergroup.find(go.ordergroup).update_attribute :price_markup_key, 'high'
      Ordergroup.find(go2.ordergroup).update_attribute :price_markup_key, 'low'
    end

    it 'can mix different markups' do
      uq = oa.price.unit_quantity
      goa.update_quantities uq, 0
      goa2.update_quantities uq, 0
      go.update_price!; go2.update_price!; oa.update_results!
      go.reload; go2.reload; oa.reload
      expect(go.price).to be > go2.price
      expect(oa.group_orders_sum[:price]).to eq uq*oa.price.fc_price(go.ordergroup) + uq*oa.price.fc_price(go2.ordergroup)
    end

  end

end
