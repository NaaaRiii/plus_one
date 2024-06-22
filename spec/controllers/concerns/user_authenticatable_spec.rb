require 'rails_helper'

class DummyController < ApplicationController
  include UserAuthenticatable

  def index
    render plain: "Hello"
  end
end

RSpec.describe DummyController, type: :controller do
  controller DummyController do
  end

  let(:user) { create(:user) }
  let(:token) { JWT.encode({ user_id: user.id, jti: SecureRandom.uuid }, Rails.application.secrets.secret_key_base, 'HS256') }

  before do
    routes.draw { get 'index' => 'dummy#index' }
  end

  describe 'GET #index' do
    context 'when the user is authenticated' do
      before do
        request.headers['Authorization'] = "Bearer #{token}"
        allow_any_instance_of(UserAuthenticatable).to receive(:fetch_token).and_return(token)
      end

      it 'allows access' do
        get :index
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the user is not authenticated' do
      it 'returns unauthorized' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe '#logged_in_user' do
    context 'when the user is logged in' do
      before do
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'does not render unauthorized' do
        expect(controller).not_to receive(:render).with(json: { error: "Please log in." }, status: :unauthorized)
        controller.send(:logged_in_user)
      end
    end

    context 'when the user is not logged in' do
      it 'renders unauthorized' do
        expect(controller).to receive(:render).with(json: { error: "Please log in." }, status: :unauthorized)
        controller.send(:logged_in_user)
      end
    end
  end
end
