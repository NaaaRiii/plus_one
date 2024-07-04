require 'rails_helper'

RSpec.describe AuthHelper, type: :helper do
  let(:token) { 'eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjo0NX0.gQKLFoh6cRzbwuh9AVJJj1IapyA_Lahe50m-S0ZJ4Uc' }

  describe '#fetch_token' do
    context 'when token is present in cookies' do
      before do
        allow(helper).to receive(:cookies).and_return(OpenStruct.new(signed: { jwt: token }))
      end

      it 'returns the token from the cookies if present' do
        expect(helper.fetch_token).to eq(token)
      end
    end

    context 'when token is present in Authorization header' do
      before do
        allow(helper.request).to receive(:headers).and_return('Authorization' => "Bearer #{token}")
      end

      it 'returns the token from the Authorization header if present' do
        expect(helper.fetch_token).to eq(token)
      end
    end
  end

  describe '#find_current_user' do
    let(:user) { create(:user) }
    let(:user_payload) { { 'user_id' => user.id } }

    context 'when user is found' do
      before do
        allow(User).to receive(:find_by).with(id: user.id).and_return(user)
      end

      it 'sets @current_user' do
        helper.find_current_user(user_payload)
        expect(helper.instance_variable_get(:@current_user)).to eq(user)
      end
    end

    context 'when user is not found' do
      before do
        allow(User).to receive(:find_by).with(id: user.id).and_return(nil)
        allow(helper).to receive(:render_unauthorized)
      end

      it 'renders unauthorized' do
        expect(helper).to receive(:render_unauthorized).with('Unauthorized2')
        helper.find_current_user(user_payload)
      end
    end
  end
end
