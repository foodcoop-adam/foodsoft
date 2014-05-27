require_relative '../spec_helper'

# this feature only makes sense when the signup plugin is enabled
if defined? FoodsoftSignup
  describe 'the signup plugin', :type => :feature do

    before do
      FoodsoftConfig.config[:use_signup] = true
    end

    def expect_signup_page(page, is=true)
      matcher = have_selector('form#new_user')
      if is
        expect(page).to matcher
      else
        expect(page).to_not matcher
      end
    end

    describe 'its signup page', :type => :feature do
      it 'is accessible when enabled' do
        visit signup_path
        expect_signup_page(page)
      end

      it 'is not accessible when disabled' do
        FoodsoftConfig.config[:use_signup] = false
        visit signup_path
        expect_signup_page(page, false)
      end

      it 'is not accessible without key when protected' do
        FoodsoftConfig.config[:use_signup] = 'abcdefgh'
        visit signup_path
        expect_signup_page(page, false)
      end

      it 'is accessible with key when protected' do
        FoodsoftConfig.config[:use_signup] = 'abcdefgh'
        visit signup_path(key: 'abcdefgh')
        expect_signup_page(page)
      end

      it 'is accessible with ordergroup an limit' do
        FoodsoftConfig.config[:signup_ordergroup_limit] = 5
        visit signup_path
        expect_signup_page(page)
      end

      it 'is not accessible with ordergroup limit 0' do
        FoodsoftConfig.config[:signup_ordergroup_limit] = 0
        visit signup_path
        expect_signup_page(page, false)
      end

      it 'is not accessible with more ordergroups than the limit' do
        FoodsoftConfig.config[:signup_ordergroup_limit] = 5
        5.times { create :ordergroup }
        visit signup_path
        expect_signup_page(page, false)
      end

      it 'can create a new user and unapproved ordergroup' do
        visit signup_path
        user = build :_user
        ordergroup = build :ordergroup
        fill_in 'user_nick', :with => user.nick if FoodsoftConfig[:use_nick]
        fill_in 'user_first_name', :with => user.first_name
        fill_in 'user_last_name', :with => user.last_name
        fill_in 'user_email', :with => user.email
        fill_in 'user_password', :with => user.password
        fill_in 'user_password_confirmation', :with => user.password
        fill_in 'user_phone', :with => user.phone
        fill_in 'user_ordergroup_contact_address', :with => Faker::Address.street_address
        find('input[type=submit]').click
        expect(page).to have_selector('.alert-success')
        newuser = User.find_by_email(user.email)
        expect(newuser).to_not be_nil
        expect(newuser.id).to_not be_nil
        expect(newuser.ordergroup).to_not be_nil
        expect(newuser.ordergroup.approved?).to be_false
      end
    end


    describe :type => :feature do
      let(:order) { create :order }
      let(:ordergroup) { create :ordergroup, :user_ids => [user.id], :approved => false }
      let(:user) { create :_user }
      before { ordergroup; login user }

      it 'disallows ordering when not approved' do
        visit new_group_order_path(:order_id => order.id)
        expect(page).to have_selector('.alert-error')
        expect(current_path).to eq root_path
      end

      it 'allows ordering when approved' do
        ordergroup.approved = true
        ordergroup.save!
        visit new_group_order_path(:order_id => order.id)
        expect(page).to_not have_selector('.alert-error')
      end
    end

    describe 'membership fee', :type => :feature do
      let(:ordergroup) { Ordergroup.create name: 'foobar' }
      let(:admin) { create :admin }
      before do
        FoodsoftConfig.config[:membership_fee] = 1+rand(5000)/100
      end

      it 'is debited' do
        expect(ordergroup.account_balance).to eq -FoodsoftConfig.config[:membership_fee]
      end

      it 'when payed approves ordergroup' do
        expect(ordergroup.approved?).to be_false
        ordergroup.add_financial_transaction! FoodsoftConfig.config[:membership_fee], 'payment', admin
        expect(ordergroup.approved?).to be_true
        expect(ordergroup.account_balance).to eq 0
      end

      it 'can be a larger donation' do
        ordergroup.add_financial_transaction! FoodsoftConfig.config[:membership_fee]+20, 'larger payment', admin
        expect(ordergroup.financial_transactions.last.amount).to eq -20
        expect(ordergroup.account_balance).to eq 0
      end


      describe 'and payment fee', :type => :feature do
        let(:pay_fee) { (0.1 + rand(240)/100) }

        def credit(og, note, delta=0)
          amount = FoodsoftConfig.config[:membership_fee] + delta
          FinancialTransaction.create amount: amount-pay_fee, ordergroup: og, note: note, user: admin, payment_amount: amount, payment_fee: pay_fee
        end

        it 'when payed approves ordergroup' do
          expect(ordergroup.approved?).to be_false
          credit ordergroup, 'payment'
          expect(ordergroup.approved?).to be_true
          expect(ordergroup.account_balance).to eq 0
        end

        it 'can be a larger donation' do
          credit ordergroup, 'larger payment', 20
          expect(ordergroup.financial_transactions.last.amount).to eq -20
          expect(ordergroup.account_balance).to eq 0
        end
      end
    end

  end
end
