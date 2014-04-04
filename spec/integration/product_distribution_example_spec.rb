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

    def dotest
      # gruppe a bestellt 2(3), weil sie auf jeden fall was von x bekommen will
      login user_a
      group_order_delta oa, 2, 3
      yield if block_given?
      # gruppe b bestellt 2(0)
      login user_b
      group_order_delta oa, 2, 0
      yield if block_given?
      # gruppe a faellt ein dass sie doch noch mehr braucht von x und aendert auf 4(1).
      login user_a
      group_order_delta oa, 2, -2
      yield if block_given?
      # die zuteilung
      order.finish!(admin)
      oa.reload
      # Endstand: insg. Bestellt wurden 6(1)
      expect([oa.quantity, oa.tolerance]).to eq [6, 1]
      # Gruppe a bekommt 3 einheiten.
      goa_a = oa.group_order_articles.joins(:group_order).where(:group_orders => {:ordergroup_id => user_a.ordergroup.id}).first
      expect(goa_a.result).to eq(3)
      # gruppe b bekommt 2 einheiten.
      goa_b = oa.group_order_articles.joins(:group_order).where(:group_orders => {:ordergroup_id => user_b.ordergroup.id}).first
      expect(goa_b.result).to eq(2)
    end

    it 'agrees to documented example', :js => true do
      dotest
    end

    if defined? FoodsoftPayorder
      it 'agrees to document example when payorder is enabled', :js => true do
        FoodsoftConfig.config[:use_payorder] = true
        dotest
      end
    end
  end

  def visit_ordering_page(order_article=oa)
    visit group_order_path(:current)
    within('.facets') do
      click_link order_article.article.article_category.name
    end
    expect(page).to have_selector("#order_article_#{order_article.id}")
  end

  def group_order_delta(oa, dq, dt)
    visit_ordering_page
    # update quantity
    if dq > 0
      dq.times { find("#order_article_#{oa.id} .quantity button[data-increment]").click }
    elsif dq < 0
      (-dq).times { find("#order_article_#{oa.id} .quantity button[data-decrement]").click }
    end
    # update tolerance
    if dt > 0
      dt.times { find("#order_article_#{oa.id} .tolerance button[data-increment]").click }
    elsif dt < 0
      (-dt).times { find("#order_article_#{oa.id} .tolerance button[data-decrement]").click }
    end
    # wait for ajax change to be done
    sleep 0.5
  end

end
