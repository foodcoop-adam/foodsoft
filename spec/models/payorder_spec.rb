require 'spec_helper'

# these tests are for the payorder plugin
if defined? FoodsoftPayorder
  describe :payorder do
    let(:admin)   { create :user }
    let(:article) { create :article, unit_quantity: 1 }
    let(:order)   { create :order, article_ids: [article.id] }
    let(:go)      { create :group_order, order: order }
    let(:goa)     { create :group_order_article, group_order: go, order_article: order.order_articles.first }

    before do
      FoodsoftConfig.config[:use_payorder] = true
    end

    def update_quantities(goa, quantity, tolerance)
      goa.update_quantities(quantity, tolerance)
      goa.order_article.update_results!
    end
    def credit(ordergroup, amount)
      ordergroup.add_financial_transaction! amount, 'for ordering', admin
    end

    describe :ordergroup do

      it 'has no result without funds' do
        update_quantities goa, 1, 0
        order.finish!(admin)
        expect(goa.reload.result).to eq 0
      end

      it 'has result with funds before ordering' do
        credit go.ordergroup, article.fc_price*3
        update_quantities goa, 3, 0
        order.finish!(admin)
        expect(goa.reload.result).to eq 3
      end

      it 'has result when funds are added after ordering' do
        update_quantities goa, 2, 0
        credit go.ordergroup, article.fc_price*2
        order.finish!(admin)
        expect(goa.reload.result).to eq 2
      end

      it 'has old result when updating group order after payment' do
        update_quantities goa,  8, 0
        credit go.ordergroup, article.fc_price*8
        update_quantities goa, 10, 0
        order.finish!(admin)
        expect(goa.reload.result).to eq 8
      end

      describe 'with multiple orders' do
        let(:article2)  { create :article, unit_quantity: 1 }
        let(:article3)  { create :article, unit_quantity: 1, price: article.price, deposit: article.deposit, tax: article.tax }
        let(:order)     { create :order, article_ids: [article.id, article2.id, article3.id] }
        let(:goa2)      { create :group_order_article, group_order: go, order_article: order.order_articles.second }
        let(:goa3)      { create :group_order_article, group_order: go, order_article: order.order_articles.third }

        it 'gets first article when paid only first' do
          update_quantities goa,  1, 0
          update_quantities goa2, 2, 0
          credit go.ordergroup, article.fc_price
          order.finish!(admin)
          expect([goa, goa2].map(&:reload).map(&:result)).to eq [1, 0]
        end

        # might be nice, but this is not the case at the moment (0 result for both)
        #it 'gets second article when paid only second' do
        #  update_quantities goa3, 2, 0
        #  update_quantities goa,  1, 0
        #  credit go.ordergroup, article.fc_price
        #  order.finish!(admin)
        #  expect([goa, goa3].map(&:reload).map(&:result)).to eq [1, 0]
        #end

        it 'gets one article when not paid enough for two' do
          update_quantities goa,  1, 0
          update_quantities goa2, 2, 0
          credit go.ordergroup, article.fc_price + article2.fc_price/2
          order.finish!(admin)
          expect([goa, goa3].map(&:reload).map(&:result)).to eq [1, 0]
        end
      end

    end
  end
end
