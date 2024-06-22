require 'rails_helper'

RSpec.describe AuthHelper, type: :helper do
  let(:user) { create(:user) }
  let(:token) { JWT.encode({ user_id: user.id }, Rails.application.secrets.secret_key_base, 'HS256') }

  describe '#decode_token' do
    it 'returns the payload if the token is valid' do
      decoded_token = helper.decode_token(token)
      expect(decoded_token['user_id']).to eq(user.id)
    end

    it 'returns nil if the token is invalid' do
      decoded_token = helper.decode_token('invalid_token')
      expect(decoded_token).to be_nil
    end
  end

  describe '#fetch_token' do
    it 'returns the token from the cookies if present' do
      cookies.signed[:jwt] = token
      expect(helper.fetch_token).to eq(token)
    end

    it 'returns the token from the authorization header if present' do
      request.headers['Authorization'] = "Bearer #{token}"
      expect(helper.fetch_token).to eq(token)
    end
  end

  describe '#find_current_user' do
    it 'sets @current_user if the user is found' do
      helper.find_current_user({ 'user_id' => user.id })
      expect(helper.instance_variable_get(:@current_user)).to eq(user)
    end

    it 'renders unauthorized if the user is not found' do
      expect(helper).to receive(:render_unauthorized).with('Unauthorized2')
      helper.find_current_user({ 'user_id' => -1 })
    end
  end
end
