require_relative '../spec_helper'

describe LoginController do

  # some security-related checks
  describe 'POST accept_invitation' do
    let(:user) { build :user }
    let(:user_attrs) { {
      nick: user.nick,
      first_name: user.first_name,
      last_name: user.last_name,
      email: invite.email,
      password: user.password,
      password_confirmation: user.password
    } }
    let(:req_user_attrs) { user_attrs }
    let(:invite) { create :invite }
    let(:token) { invite.token }

    before do
      post :accept_invitation, token: token, user: req_user_attrs, foodcoop: FoodsoftConfig.scope
    end

    it 'can create a user' do
      expect(User.where(email: invite.email).first).to_not be_nil
    end

    describe 'requesting group' do
      let(:new_group_id) { create(:ordergroup).id }
      let(:req_user_attrs) { user_attrs.merge({ordergroup: {id: new_group_id}}) }

      it 'does not change group' do
        expect(User.where(email: invite.email).first.ordergroup.id).to_not eq new_group_id
      end
    end

    describe 'invitation to group' do
      let(:group) { create :ordergroup }
      let(:invite) { create :invite, group: group }
      let(:new_group_id) { create(:ordergroup).id }
      let(:req_user_attrs) { user_attrs.merge({ordergroup: {id: new_group_id}}) }

      it 'can create a user' do
        expect(User.where(email: invite.email).first).to_not be_nil
      end

      describe 'requesting different group' do
        it 'does not change group' do
          expect(User.where(email: invite.email).first.ordergroup.id).to eq group.id
        end
      end

      describe 'requesting new group' do
        let(:new_group_id) { 'new' }
        it 'does not change group' do
          expect(User.where(email: invite.email).first.ordergroup.id).to eq group.id
        end
      end
    end
  end
end
