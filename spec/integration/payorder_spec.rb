require_relative '../spec_helper'

feature 'payorder full flow', js: true do
  let(:admin) { create :admin }
  let(:user_a) { create :user_and_ordergroup }
  let(:user_b) { create :user_and_ordergroup }
  let(:user_c) { create :user_and_ordergroup }
  let(:supplier) { create :supplier }
  let(:article) { create :article, supplier: supplier, unit_quantity: 5 }
  let(:order) { create(:order, supplier: supplier, article_ids: [article.id]) }
  let(:oa) { order.order_articles.first }
  let(:goa_a) { oa.group_order_articles.joins(:group_order).where(:group_orders => {:ordergroup_id => user_a.ordergroup.id}).first }
  let(:goa_b) { oa.group_order_articles.joins(:group_order).where(:group_orders => {:ordergroup_id => user_b.ordergroup.id}).first }
  let(:goa_c) { oa.group_order_articles.joins(:group_order).where(:group_orders => {:ordergroup_id => user_c.ordergroup.id}).first }

  before do
    order # make sure order is referenced
    FoodsoftConfig.config[:use_payorder] = true
    FoodsoftConfig.config[:payorder_remove_unpaid] = true
    FoodsoftConfig.config[:payorder_payment] = 'root_path'
    FoodsoftConfig.config[:payorder_payment] = 'new_payments_mollie_path' if can_use_mollie?
  end

  it 'agrees' do
    # group_a orders 3+1
    login user_a
    group_order_delta oa, 3, 1
    # group_b orders 2+3 and pays
    login user_b
    group_order_delta oa, 2, 3
    group_order_pay user_b
    # group_a orders 5+1 and pays
    login user_a
    group_order_delta oa, 2, 0
    group_order_pay user_a
    # group_c orders 3+0 and doesn't pay or confirm
    login user_c
    group_order_delta oa, 3, 0
    # group_a changes order to 2+1
    login user_a
    group_order_delta oa, -3, 0
    # group_b changes order to 8+3 and doesn't pay
    login user_b
    group_order_delta oa, 6, 0
    # finish
    order.finish!(admin)
    oa.reload
    # check
    expect([oa.quantity, oa.tolerance]).to eq [4, 4]
    expect([goa_a, goa_b].map(&:result)).to eq [3, 2]
    expect(goa_c).to be_nil
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

  def group_order_confirm
    visit group_order_path(:current)
    within '.page-header' do
      click_link_or_button I18n.t('helpers.payorder.confirm')
      expect(page).to have_link I18n.t('helpers.payorder.paid')
    end
  end

  def group_order_pay(ordergroup)
    visit group_order_path(:current)
    within '.page-header' do
      click_link_or_button I18n.t('helpers.payorder.payment')
    end
    if can_use_mollie?
      # on foodsoft_mollie payment page
      click_link_or_button I18n.t('payments.mollie_ideal.form.submit')
      # on external Mollie test payment page
      expect(page).to have_content 'Mollie'
      expect(page).to have_content 'This is not a real payment.'
      find('form [type=submit]').click
    else
      ordergroup = ordergroup.ordergroup if ordergroup.is_a? User
      ordergroup.add_financial_transaction! -ordergroup.get_available_funds, 'for ordering', admin
    end
    visit group_order_path(:current)
    within '.page-header' do
      expect(page).to have_link I18n.t('helpers.payorder.paid')
    end
  end

  def can_use_mollie?
    defined? FoodsoftMollie and cfg = FoodsoftConfig[:mollie] and cfg['api_key']
    # @todo would be nice to make sure we have a test api key, else it wouldn't work anyway
  end

end
