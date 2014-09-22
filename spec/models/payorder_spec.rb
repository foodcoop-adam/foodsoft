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
      FoodsoftConfig.config[:payorder_payment] = 'root_path'
    end

    def update_quantities(goa, quantity, tolerance)
      goa.update_quantities(quantity, tolerance)
      goa.order_article.reload.update_results!
      goa.group_order.update_price!
    end
    def credit(ordergroup, amount, paid=true)
      t = ordergroup.add_financial_transaction! 0, 'for ordering', admin, payment_amount: amount, payment_state: 'pending'
      t.update_attributes! amount: amount, payment_state: 'paid' if paid
      # an alternative would have been the following, but the above happens for online payments and
      #   is slightly more tricky with respect to triggering hooks, so we do that for testing
      #ordergroup.add_financial_transaction! amount, 'for ordering', admin
    end

    def finish_and_check_result(goa, result)
      goa = [goa] unless goa.is_a? Array
      result = [result] unless result.is_a? Array
      goa.map(&:order_article).map(&:order).uniq.map {|order| order.finish! admin}
      goa.map! do |goa|
        begin
          goa.reload
        rescue ActiveRecord::RecordNotFound
          nil
        end
      end
      expect(goa.map {|goa| goa ? goa.result : nil}).to eq result
      # @todo sorry, couldn't resist the one-liner
      oas_with_result = Hash[ goa.compact.map(&:order_article).zip(result).group_by(&:first).map {|a| [a[0], a[1].map(&:last).sum]} ]
      expect(oas_with_result.keys.map(&:units_to_order)).to eq oas_with_result.values
    end

    describe :ordergroup do

      it 'has no result without funds' do
        update_quantities goa, 1, 0
        finish_and_check_result goa, 0
      end

      it 'has result with exact funds before ordering' do
        credit go.ordergroup, article.fc_price*3
        update_quantities goa, 3, 0
        finish_and_check_result goa, 3
      end

      it 'has result with plenty of funds before ordering' do
        credit go.ordergroup, article.fc_price*120
        update_quantities goa, 1, 0
        finish_and_check_result goa, 1
      end

      it 'has result when funds are added after ordering' do
        update_quantities goa, 2, 0
        credit go.ordergroup, article.fc_price*2
        finish_and_check_result goa, 2
      end

      it 'has old result when updating group order after payment' do
        update_quantities goa,  8, 0
        credit go.ordergroup, article.fc_price*8
        update_quantities goa, 10, 0
        finish_and_check_result goa, 8
      end

      it 'has no result when paid 0' do
        update_quantities goa, 1, 0
        credit go.ordergroup, 0
        finish_and_check_result goa, 0
      end

      describe 'order total update' do

        it 'when unpaid' do
          update_quantities goa, 5, 0
          expect(order.sum(:net)).to eq 0
        end

        it 'when paid' do
          update_quantities goa, 5, 0
          credit go.ordergroup, article.fc_price*5
          expect(order.sum(:net)).to eq article.price*5
        end

        it 'when paid 0' do
          update_quantities goa, 5, 0
          credit go.ordergroup, 0
          expect(order.sum(:net)).to eq 0
        end
      end

      describe 'with multiple group orders' do
        let(:go2)       { create :group_order, order: order }
        let(:goa2)      { create :group_order_article, group_order: go2, order_article: order.order_articles.first }

        before do
          credit go2.ordergroup, article.fc_price
          update_quantities goa,  1, 0
          update_quantities goa2, 1, 0
          [goa, goa2, go, go2].map(&:reload)
        end

        it 'only person who paid gets article' do
          finish_and_check_result [goa, goa2], [0, 1]
        end

        it 'only person who paid is shown as ordered' do
          expect([goa, goa2].map(&:result)).to eq [0, 1]
        end

        it 'has correct group order sums when open' do
          expect(go.price).to be_within(1e-2).of article.fc_price
          expect(go2.price).to be_within(1e-2).of article.fc_price
        end

        it 'has correct group order sums when finished' do
          finish_and_check_result [goa, goa2], [0, 1]
          expect(go.reload.price).to be_within(1e-2).of 0
          expect(go2.reload.price).to be_within(1e-2).of article.fc_price
        end

        it 'results in correct available funds' do
          expect(go.ordergroup.get_available_funds).to be_within(1e-2).of -article.fc_price
          expect(go2.ordergroup.get_available_funds).to be_within(1e-2).of 0
        end
      end

      describe 'with multiple order articles' do
        let(:article2)  { create :article, unit_quantity: 1 }
        let(:article3)  { create :article, unit_quantity: 1, price: article.price, deposit: article.deposit, tax: article.tax }
        let(:order)     { create :order, article_ids: [article.id, article2.id, article3.id] }
        let(:goa2)      { create :group_order_article, group_order: go, order_article: order.order_articles.second }
        let(:goa3)      { create :group_order_article, group_order: go, order_article: order.order_articles.third }

        it 'gets first article when paid only first' do
          update_quantities goa,  1, 0
          update_quantities goa2, 2, 0
          credit go.ordergroup, article.fc_price
          finish_and_check_result [goa, goa2],  [1, 0]
        end

        it 'gets second article when paid only second' do
          update_quantities goa3, 2, 0
          update_quantities goa,  1, 0
          credit go.ordergroup, article.fc_price
          finish_and_check_result [goa, goa3],  [1, 0]
        end

        it 'gets one article when not paid enough for two' do
          update_quantities goa,  1, 0
          update_quantities goa3, 2, 0
          credit go.ordergroup, article.fc_price + article3.fc_price/2
          finish_and_check_result [goa, goa3],  [1, 0]
        end
      end

      describe 'with multiple orders' do
        let(:article2) { create :article, unit_quantity: 1 }
        let(:order2)   { create :order, article_ids: [article2.id] }
        let(:go2)      { create :group_order, order: order2, ordergroup: go.ordergroup }
        let(:goa2)     { create :group_order_article, group_order: go2, order_article: order2.order_articles.first }

        it 'has no result without funds' do
          update_quantities goa, 1, 0
          update_quantities goa2, 3, 0
          finish_and_check_result [goa, goa2],  [0, 0]
        end

        it 'has result with exact funds before ordering' do
          credit go.ordergroup, article.fc_price*5 + article2.fc_price*3
          update_quantities goa,  5, 0
          update_quantities goa2, 3, 0
          finish_and_check_result [goa, goa2],  [5, 3]
        end

        it 'gets first when paid only first' do
          update_quantities goa,  1, 0
          update_quantities goa2, 2, 0
          credit go.ordergroup, article.fc_price
          finish_and_check_result [goa, goa2],  [1, 0]
        end

        it 'gets one article when not paid enough for two' do
          update_quantities goa,  1, 0
          update_quantities goa2, 2, 0
          credit go.ordergroup, article.fc_price + article2.fc_price/2
          finish_and_check_result [goa, goa2],  [1, 0]
        end
      end

      describe 'with timeout' do
        before do
          FoodsoftConfig.config[:quantity_time_delta_server] = 1
        end

        it 'merges unpayed quantities' do
          update_quantities goa, 1, 0
          expect(goa.reload.group_order_article_quantities.count).to eq 1
          update_quantities goa, 2, 0
          expect(goa.reload.group_order_article_quantities.count).to eq 1
        end

        it 'merges payed quantities' do
          credit go.ordergroup, article.fc_price*2
          update_quantities goa, 1, 0
          expect(goa.reload.group_order_article_quantities.count).to eq 1
          update_quantities goa, 2, 0
          expect(goa.reload.group_order_article_quantities.count).to eq 1
        end

        it 'does not merge unpayed with payed quantity' do
          credit go.ordergroup, article.fc_price
          update_quantities goa, 1, 0
          expect(goa.reload.group_order_article_quantities.count).to eq 1
          update_quantities goa, 2, 0
          expect(goa.reload.group_order_article_quantities.count).to eq 2
        end

        it 'does not merge payed with unpayed quantity' do
          update_quantities goa, 1, 0
          expect(goa.reload.group_order_article_quantities.count).to eq 1
          credit go.ordergroup, article.fc_price*2
          update_quantities goa, 3, 0
          expect(goa.reload.group_order_article_quantities.count).to eq 2
        end

        it 'does not merge unpayed quantities after timeout' do
          update_quantities goa, 1, 0
          expect(goa.reload.group_order_article_quantities.count).to eq 1
          sleep 1.2
          update_quantities goa, 2, 0
          expect(goa.reload.group_order_article_quantities.count).to eq 2
        end
      end

      describe 'with remove unpaid' do
        let(:article2)  { create :article, unit_quantity: 1 }
        let(:order)     { create :order, article_ids: [article.id, article2.id] }
        let(:goa2)      { create :group_order_article, group_order: go, order_article: order.order_articles.second }

        before do
          FoodsoftConfig.config[:payorder_remove_unpaid] = true
        end

        it 'removes second article when only paid first' do
          update_quantities goa,  1, 0
          update_quantities goa2, 2, 0
          credit go.ordergroup, article.fc_price
          finish_and_check_result [goa, goa2], [1, nil]
          expect(article.order_articles.first.group_order_articles.count).to eq 1
        end

        it 'removes group order when unpaid' do
          ordergroup = go.ordergroup
          update_quantities goa, 1, 0
          finish_and_check_result goa, nil
          expect(order.sum).to eq 0
          expect(ordergroup.group_orders.count).to eq 0
          expect(article.order_articles.first.group_order_articles.count).to eq 0
        end

        it 'removes group order when paid 0' do
          ordergroup = go.ordergroup
          update_quantities goa, 1, 0
          credit go.ordergroup, 0
          finish_and_check_result goa, nil
          expect(order.sum).to eq 0
          expect(ordergroup.group_orders.count).to eq 0
          expect(article.order_articles.first.group_order_articles.count).to eq 0
        end

      end

    end
  end
end
