require_relative '../spec_helper'

describe 'the supplier mailer plugin' do

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
      FoodsoftConfig.config[:send_order_on_finish] = [mailto]
      order.finish!(user)
      email = ActionMailer::Base.deliveries.first
      expect(email.to[0]).to eq mailto
    end

    it 'to supplier' do
      supplier.order_howto = mailto
      supplier.save!
      FoodsoftConfig.config[:send_order_on_finish] = ['%{supplier}']
      order.finish!(user)
      email = ActionMailer::Base.deliveries.first
      expect(email.to[0]).to eq supplier.order_howto
    end

    it 'not to supplier when it is empty' do
      supplier.order_howto = nil
      supplier.save!
      FoodsoftConfig.config[:send_order_on_finish] = ['%{supplier}']
      order.finish!(user)
      email = ActionMailer::Base.deliveries.first
      expect((email.to[0] rescue nil)).to_not eq mailto
    end

    it 'to foodcoop email' do
      FoodsoftConfig.config[:send_order_on_finish] = ['%{contact.email}']
      order.finish!(user)
      email = ActionMailer::Base.deliveries.first
      expect(email.to[0]).to eq FoodsoftConfig[:contact]['email']
    end

    it 'has an attachment' do
      FoodsoftConfig.config[:send_order_on_finish] = [mailto]
      order.finish!(user)
      email = ActionMailer::Base.deliveries.first
      expect(email.attachments.count).to_not eq 0
    end
  end


end
