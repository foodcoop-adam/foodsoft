require_relative '../spec_helper'

describe 'invitation', :type => :feature do
  let(:group) { create :ordergroup }
  let(:invite) { create :invite }

  describe :type => :feature do
    it 'can be accessed' do
      visit accept_invitation_path(token: invite.token)
      expect(page).to have_selector('form.new_user')
    end

    it 'cannot be accessed when overdue' do
      invite.update_attribute :expires_at, 1.year.ago # no validation, or expires_at is overwritten
      visit accept_invitation_path(token: invite.token)
      expect(page).to_not have_selector('form.new_user')
    end

    it 'creates a user with an existing ordergroup' do
      invite = create :invite, group: group
      visit accept_invitation_path(token: invite.token)
      user = test_accept_invitation_path(email: invite.email)
      expect(user).to_not be nil
      expect(user.ordergroup.id).to eq group.id
    end

    it 'creates a user with a new ordergroup' do
      visit accept_invitation_path(token: invite.token)
      user = test_accept_invitation_path(email: invite.email)
      expect(user).to_not be nil
      expect(user.ordergroup).to_not be nil
    end
  end

  describe :type => :feature do
    let(:user) { create :user, groups: [create(:ordergroup)] }
    let(:admin) { create :admin }

    it 'can be created' do
      login user
      visit new_invite_path(id: user.ordergroup.id)
      email = Faker::Internet.email
      fill_in 'invite_email', with: email
      find('input[type=submit]').click
      expect(Invite.where(email: email).first).to_not be nil
    end

    it 'cannot be sent to multiple users by default' do
      login user
      visit new_invite_path(id: user.ordergroup.id)
      emails = [Faker::Internet.email, Faker::Internet.email]
      fill_in 'invite_email', with: emails.join(', ')
      find('input[type=submit]').click
      expect(Invite.where(email: emails.first).first).to be nil
    end

    it 'admin can send to multiple users' do
      login admin
      visit new_invite_path
      emails = [Faker::Internet.email, Faker::Internet.email]
      fill_in 'invite_email', with: emails.join(', ')
      find('input[type=submit]').click
      expect(Invite.where(email: emails[0]).first).to_not be nil
      expect(Invite.where(email: emails[1]).first).to_not be nil
    end

  end

  # the following tests are perhaps a bit superfluous, but rather be safe than sorry
  describe 'api', :type => :feature do
    it 'can create a user' do
      user_attrs = new_user_attributes(email: invite.email)
      post accept_invitation_path(token: invite.token), {user: user_attrs}
      expect(User.where(email: invite.email).first).to_not be nil
    end

    it 'cannot request a different ordergroup when one is given' do
      invite = create :invite, group: group
      user_attrs = new_user_attributes(email: invite.email, ordergroup: {id: create(:ordergroup).id})
      post accept_invitation_path(token: invite.token), {user: user_attrs}
      expect(User.where(email: invite.email).first.ordergroup.id).to eq group.id
    end

    it 'cannot request a new ordergroup when one is given' do
      invite = create :invite, group: group
      user_attrs = new_user_attributes(email: invite.email, ordergroup: {id: 'new'})
      post accept_invitation_path(token: invite.token), {user: user_attrs}
      expect(User.where(email: invite.email).first.ordergroup.id).to eq group.id
    end

    it 'cannot request a different ordergroup when none is given' do
      invite = create :invite
      newgroup = create :ordergroup
      user_attrs = new_user_attributes(email: invite.email, ordergroup: {id: newgroup.id})
      post accept_invitation_path(token: invite.token), {user: user_attrs}
      expect(User.where(email: invite.email).first.ordergroup.id).to_not eq newgroup.id
    end
  end


  def test_accept_invitation_path(user_attributes)
    user = build :user, user_attributes
    within('form.new_user, form.edit_user') do
      fill_in 'user_email', :with => user.email
      fill_in 'user_first_name', :with => user.first_name unless user.first_name.blank?
      fill_in 'user_last_name', :with => user.last_name unless user.last_name.blank?
      fill_in 'user_phone', :with => user.phone unless user.phone.blank?
      fill_in 'user_password', :with => user.password unless user.password.blank?
      fill_in 'user_password_confirmation', :with => user.password unless user.password.blank?
      # submit
      find('input[type=submit]').click
    end
    expect(page).to have_content(I18n.t('login.controller.accept_invitation.notice'))
    User.where(email: user.email).first
  end

  def new_user_attributes(user_attributes)
    user = build :user, user_attributes
    {
      nick: user.nick,
      first_name: user.first_name,
      last_name: user.last_name,
      email: user.email,
      password: user.password,
      password_confirmation: user.password
    }
  end

end
