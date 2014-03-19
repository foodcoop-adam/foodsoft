require_relative '../spec_helper'

describe 'the supplier mailer' do

  let(:supplier) { create :supplier, article_count: 1 }
  let(:order)    { create :order, supplier: supplier }
  let(:oa)       { order.order_articles.first }
  let(:user)     { create :user_and_ordergroup }
  let(:go)       { create :group_order, order: order, ordergroup: user.ordergroup }
  let(:goa)      { create :group_order_article, group_order: go, order_article: oa }


  describe 'knows where to' do
    it 'send the order' do
      supplier.order_howto = Faker::Internet.email
      expect(supplier.order_send_email).to eq supplier.order_howto
    end

    it 'not send the order' do
      supplier.order_howto = "You must not send it to foo@bar.test"
      expect(supplier.order_send_email).to be nil
    end
  end


  describe 'knows when an order can be sent' do
    it 'without articles' do
      expect(order.can_send).to eq :result
    end

    it 'not meeting minimum order quantity' do
      supplier.min_order_quantity = oa.price.gross_price * oa.price.unit_quantity * 2
      supplier.save!
      goa.update_quantities(oa.price.unit_quantity, 0)
      oa.update_results!
      expect(order.can_send).to eq :min_quantity
    end

    it 'meeting all conditions' do
      goa.update_quantities(oa.price.unit_quantity, 0)
      oa.update_results!
      expect(order.can_send).to eq true
    end
  end


  describe 'sends mail when order is finished' do
    let(:mailto) { Faker::Internet.email }
    before do
      ActionMailer::Base.deliveries.clear
      goa.update_quantities(oa.price.unit_quantity, 0)
      oa.update_results!
    end

    it 'to a specified addres' do
      FoodsoftConfig.config[:send_order_on_finish] = 'cc_only'
      FoodsoftConfig.config[:send_order_on_finish_cc] = [mailto]
      order.finish!(user)
      email = ActionMailer::Base.deliveries.first
      expect(email.to).to include mailto
    end

    it 'to supplier' do
      supplier.order_howto = mailto
      supplier.save!
      FoodsoftConfig.config[:send_order_on_finish] = true
      order.finish!(user)
      email = ActionMailer::Base.deliveries.first
      expect(email.to[0]).to eq supplier.order_howto
    end

    it 'not to supplier when it is empty' do
      supplier.order_howto = nil
      supplier.save!
      FoodsoftConfig.config[:send_order_on_finish] = true
      order.finish!(user)
      email = ActionMailer::Base.deliveries.first
      expect((email.to rescue [])).to_not include mailto
    end

    it 'to foodcoop email' do
      FoodsoftConfig.config[:send_order_on_finish] = 'cc_only'
      FoodsoftConfig.config[:send_order_on_finish_cc] = ['%{contact.email}']
      order.finish!(user)
      email = ActionMailer::Base.deliveries.first
      expect(email.to).to include FoodsoftConfig[:contact]['email']
    end

    it 'has two attachments' do
      FoodsoftConfig.config[:send_order_on_finish] = 'cc_only'
      FoodsoftConfig.config[:send_order_on_finish_cc] = [mailto]
      order.finish!(user)
      email = ActionMailer::Base.deliveries.first
      expect(email.attachments.count).to eq 2
    end
  end


end
