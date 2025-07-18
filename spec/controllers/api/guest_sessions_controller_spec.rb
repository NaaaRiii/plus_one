require 'rails_helper'

RSpec.describe Api::GuestSessionsController, type: :controller do
  let(:guest_email) { 'test2user@example.com' }
  let(:guest_password) { '?TePPstPd0ajsrhpig824t!' }

  before do
    @original_guest_email = ENV['GUEST_EMAIL']
    @original_guest_password = ENV['GUEST_PASSWORD']
    ENV['GUEST_EMAIL'] = guest_email
    ENV['GUEST_PASSWORD'] = guest_password
  end

  after do
    ENV['GUEST_EMAIL'] = @original_guest_email
    ENV['GUEST_PASSWORD'] = @original_guest_password
  end

  describe 'POST #create' do
    context 'when guest user exists and credentials are correct' do
      let!(:guest_user) { create(:user, email: guest_email, password: guest_password) }

      before do
        # 固定トークンを返すようスタブし、検証を簡素化
        allow_any_instance_of(User).to receive(:generate_auth_token).and_return('dummy_token')
      end

      it 'returns 200 OK and a JWT token with basic user info' do
        post :create

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['token']).to eq 'dummy_token'
        expect(json['user']).to include(
          'id' => guest_user.id,
          'email' => guest_user.email,
          'name' => guest_user.name
        )
      end
    end

    context 'when guest user is not found' do
      it 'returns 404 Not Found with error message' do
        post :create

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json).to eq('error' => 'Guest user not found')
      end
    end

    context 'when password is incorrect' do
      before do
        create(:user, email: guest_email, password: 'wrong_password')
      end

      it 'returns 404 Not Found with error message' do
        post :create

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json).to eq('error' => 'Guest user not found')
      end
    end
  end
end 