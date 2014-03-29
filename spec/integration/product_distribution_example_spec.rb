require_relative '../spec_helper'

describe 'product distribution', :type => :feature do
  let(:admin) { create :admin }
  let(:user_a) { create :user_and_ordergroup }
  let(:user_b) { create :user_and_ordergroup }
  let(:supplier) { create :supplier }
  let(:article) { create :article, supplier: supplier, unit_quantity: 5 }
  let(:order) { create(:order, supplier: supplier, article_ids: [article.id]) }
  let(:oa) { order.order_articles.first }

  describe :type => :feature do
    before do
      # make sure users have enough money to order
      [user_a, user_b].each do |user|
        ordergroup = Ordergroup.find(user.ordergroup.id)
        ordergroup.add_financial_transaction! 5000, 'for ordering', admin
      end
      order # make sure order is referenced
    end

    it 'agrees to documented example', :js => true do
      # gruppe a bestellt 2(3), weil sie auf jeden fall was von x bekommen will
      login user_a
      visit_ordering_page
      # click first category
      2.times { find("#order_article_#{oa.id} .quantity button[data-increment]").click }
      3.times { find("#order_article_#{oa.id} .tolerance button[data-increment]").click }
      sleep 0.5
      # gruppe b bestellt 2(0)
      login user_b
      visit_ordering_page
      2.times { find("#order_article_#{oa.id} .quantity button[data-increment]").click }
      sleep 0.5
      # gruppe a faellt ein dass sie doch noch mehr braucht von x und aendert auf 4(1).
      login user_a
      visit_ordering_page
      2.times { find("#order_article_#{oa.id} .quantity button[data-increment]").click }
      2.times { find("#order_article_#{oa.id} .tolerance button[data-decrement]").click }
      sleep 0.5
      # die zuteilung
      order.finish!(admin)
      oa.reload
      # Endstand: insg. Bestellt wurden 6(1)
      expect(oa.quantity).to eq(6)
      expect(oa.tolerance).to eq(1)
      # Gruppe a bekommt 3 einheiten.
      goa_a = oa.group_order_articles.joins(:group_order).where(:group_orders => {:ordergroup_id => user_a.ordergroup.id}).first
      expect(goa_a.result).to eq(3)
      # gruppe b bekommt 2 einheiten.
      goa_b = oa.group_order_articles.joins(:group_order).where(:group_orders => {:ordergroup_id => user_b.ordergroup.id}).first
      expect(goa_b.result).to eq(2)
    end
  end

  def visit_ordering_page(order_article=oa)
    visit group_order_path(:current)
    within('.facets') do
      click_link order_article.article.article_category.name
    end
    expect(page).to have_selector("#order_article_#{order_article.id}")
  end

end
