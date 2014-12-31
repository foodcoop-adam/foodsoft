require_relative '../spec_helper'

describe Order, :type => :feature do
  let(:admin) { create :user, groups:[create(:workgroup, role_orders: true)] }
  let(:supplier) { create :supplier, order_howto: Faker::Internet.email }
  let(:article) { create :article, supplier: supplier, unit_quantity: 3 }
  let(:order) { create :order, supplier: supplier, article_ids: [article.id] } # need to ref article
  let(:go1) { create :group_order, order: order }
  let(:go2) { create :group_order, order: order }
  let(:oa) { order.order_articles.find_by_article_id(article.id) }
  let(:goa1) { create :group_order_article, group_order: go1, order_article: oa }
  let(:goa2) { create :group_order_article, group_order: go2, order_article: oa }

  # set quantities of group_order_articles
  def set_quantities(q1, q2)
    goa1.update_quantities(*q1)
    goa2.update_quantities(*q2)
    oa.update_results!
    reload_articles
  end

  # reload all group_order_articles
  def reload_articles
    [goa1, goa2].map(&:reload)
    oa.reload
  end

  describe :type => :feature, :js => true do
    before do
      login admin
    end

    it 'can close an order and send mail' do
      FoodsoftConfig.config[:send_order_on_finish] = true
      FoodsoftConfig.config[:send_order_on_finish_cc] = nil
      order_contact_phone = Faker::PhoneNumber.phone_number 
      delivery_contact_name = Faker::Name.name
      close_order do
        fill_in 'order_info_order_contact_phone', :with => order_contact_phone
        fill_in 'order_info_delivery_contact_phone', :with => Faker::PhoneNumber.phone_number 
        fill_in 'order_info_delivery_contact_name', :with => delivery_contact_name
        fill_in 'order_info_delivered_before_date', :with => Time.now.strftime('%Y-%m-%d')
        fill_in 'order_info_delivered_before_time', :with => Time.now.strftime('%H:%M')
      end
      expect(order).to be_finished
      expect(page).to_not have_link I18n.t('orders.index.action_end')
      email = ActionMailer::Base.deliveries.select {|email| email.to[0] == supplier.order_howto}.first
      expect(email).to_not be_nil
      expect(email.text_part.body.to_s).to include delivery_contact_name
      expect(email.text_part.body.to_s).to include order_contact_phone
    end

    it 'can close an order without sending an email' do
      close_order
      expect(order).to be_finished
      expect(page).to_not have_link I18n.t('orders.index.action_end')
    end
  end

  def close_order
    set_quantities [2,0], [1,0]
    visit orders_path
    click_link_or_button I18n.t('orders.index.action_end')
    expect(page).to have_selector('#modalContainer form')
    within('#modalContainer form') do
      find('input[type="submit"]').click unless block_given? and yield == false
    end
    expect(page).to_not have_selector('#modalContainer form')
    order.reload
  end

end
