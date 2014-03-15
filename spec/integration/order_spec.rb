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
    before { login admin }
    before { FoodsoftConfig.config[:send_order_on_finish] = ['%{supplier}'] }

    it 'can close an order and send mail' do
      set_quantities [2,0], [1,0]
      visit orders_path
      click_link_or_button I18n.t('orders.index.action_end')
      expect(page).to have_selector('#modalContainer form')
      order_contact_phone = Faker::PhoneNumber.phone_number 
      delivery_contact_name = Faker::Name.name
      within('#modalContainer form') do
        fill_in 'order_info_order_contact_phone', :with => order_contact_phone
        fill_in 'order_info_delivery_contact_phone', :with => Faker::PhoneNumber.phone_number 
        fill_in 'order_info_delivery_contact_name', :with => delivery_contact_name
        fill_in 'order_info_delivered_before', :with => Time.now
        find('input[type="submit"]').click
      end
      expect(page).to_not have_selector('#modalContainer form')
      expect(page).to_not have_link I18n.t('orders.index.action_end')
      email = ActionMailer::Base.deliveries.first
      expect(email.to[0]).to eq supplier.order_howto
      expect(email.text_part.body.to_s).to include delivery_contact_name
      expect(email.text_part.body.to_s).to include order_contact_phone
    end

  end

end
