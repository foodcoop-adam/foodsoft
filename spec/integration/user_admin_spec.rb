require_relative '../spec_helper'

feature 'user admin', js: true do
  let(:admin) { create :admin }
  before { login admin }

  describe 'can create a user' do
    let(:user) { build :_user }

    it 'without ordergroup' do
      visit new_admin_user_path
      new_user = test_edit_user(user, nil)
      expect(new_user).to_not be_nil
      expect(new_user.ordergroup).to be_nil
      expect(new_user.name).to eq user.name
    end

    it 'with existing ordergroup' do
      ordergroup = create :ordergroup
      visit new_admin_user_path
      new_user = test_edit_user(user, ordergroup)
      expect(new_user).to_not be_nil
      expect(new_user.ordergroup).to_not be_nil
      expect(new_user.ordergroup.id).to eq ordergroup.id
    end

    it 'with a new ordergroup' do
      visit new_admin_user_path
      ordergroup = build :ordergroup, :contact_address => Faker::Address.street_address
      new_user = test_edit_user(user, ordergroup)
      expect(new_user).to_not be_nil
      expect(new_user.ordergroup).to_not be_nil
      expect(new_user.ordergroup.contact_address).to eq ordergroup.contact_address
    end
  end

  describe 'can edit a user' do
    let(:user) { create :_user }

    it 'and associate it to an existing ordergroup' do
      ordergroup = create :ordergroup
      expect(user.ordergroup).to be_nil
      visit edit_admin_user_path(user)
      test_edit_user(user, ordergroup)
      expect(user.ordergroup).to_not be_nil
      expect(user.ordergroup.id).to eq ordergroup.id
    end

    it 'and dissociate it from an ordergroup' do
      user.ordergroup = create :ordergroup
      expect(user.ordergroup).to_not be_nil
      visit edit_admin_user_path(user)
      test_edit_user(user, nil)
      expect(user.ordergroup).to be_nil
    end

    it 'and create a new ordergroup' do
      ordergroup = build :ordergroup, :contact_address => Faker::Address.street_address
      expect(user.ordergroup).to be_nil
      visit edit_admin_user_path(user)
      test_edit_user(user, ordergroup)
      expect(user.ordergroup).to_not be_nil
      expect(user.ordergroup.contact_address).to eq ordergroup.contact_address
    end
  end


  def test_edit_user(user, ordergroup)
    within('form.new_user, form.edit_user') do
      # fill in user fields
      fill_in 'user_email', :with => user.email
      fill_in 'user_first_name', :with => user.first_name unless user.first_name.blank?
      fill_in 'user_last_name', :with => user.last_name unless user.last_name.blank?
      fill_in 'user_phone', :with => user.phone unless user.phone.blank?
      fill_in 'user_password', :with => user.password unless user.password.blank?
      fill_in 'user_password_confirmation', :with => user.password unless user.password.blank?
      # fill in ordergroup fields
      if ordergroup.nil?
        #select '', :from => 'user_ordergroup_id'
        select2 /^$/, from: User.human_attribute_name(:ordergroup)
      elsif ordergroup.new_record?
        #select 'new', :from => 'user_ordergroup_id'
        select2 '(new ordergroup)', from: User.human_attribute_name(:ordergroup)
        fill_in 'user_ordergroup_contact_address', :with => ordergroup.contact_address unless ordergroup.contact_address.nil?
      else
        #select ordergroup.name, :from => 'user_ordergroup_id' # XXX ordergroup.id doesn't work :(
        select2 ordergroup.name, from: User.human_attribute_name(:ordergroup)
      end
      # submit
      find('input[type=submit]').click
    end
    expect(page).to have_content('User was successfully') # TODO i18n
    User.where(email: user.email).first
  end

end
