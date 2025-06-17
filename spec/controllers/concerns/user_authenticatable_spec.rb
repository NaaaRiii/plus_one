require 'rails_helper'

RSpec.describe UserAuthenticatable, type: :controller do
  controller(ActionController::Base) do
    include UserAuthenticatable

    def index
      render plain: "Hello"
    end

    def show
      correct_user
      render plain: "Authorized" unless performed?
    end

    # Dummy implementations to satisfy before_action and specs
    def authenticate_user
      token = fetch_token
      return render json: { error: 'Unauthorized' }, status: :unauthorized unless token

      begin
        payload = decode_token
        @current_user = User.find_by(id: payload['user_id'])
      rescue StandardError
        return render json: { error: 'Unauthorized' }, status: :unauthorized
      end

      render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
    end

    def fetch_token; end
    def decode_token; end
    attr_reader :current_user
  end

  let(:user) { create(:user) }
  let(:token) { JWT.encode({ user_id: user.id, jti: SecureRandom.uuid }, Rails.application.secrets.secret_key_base, 'HS256') }

  before do
    routes.draw do
      get 'index' => 'anonymous#index'
      get 'show/:id' => 'anonymous#show'
    end
  end

  describe 'GET #index' do
    context 'when the user is authenticated' do
      before do
        allow(controller).to receive(:fetch_token).and_return(token)
        allow(controller).to receive(:decode_token).and_return({ 'user_id' => user.id })
        allow(User).to receive(:find_by).with(id: user.id).and_return(user)
      end

      it 'allows access' do
        get :index
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the user is not authenticated' do
      before do
        allow(controller).to receive(:fetch_token).and_return(nil)
      end

      it 'returns unauthorized' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when token is invalid' do
      before do
        allow(controller).to receive(:fetch_token).and_return('invalid_token')
        allow(controller).to receive(:decode_token).and_raise(JWT::DecodeError)
      end

      it 'returns unauthorized' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when user does not exist' do
      before do
        allow(controller).to receive(:fetch_token).and_return(token)
        allow(controller).to receive(:decode_token).and_return({ 'user_id' => 999_999 })
        allow(User).to receive(:find_by).with(id: 999_999).and_return(nil)
      end

      it 'returns unauthorized' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe '#logged_in_user' do
    context 'when the user is logged in' do
      before do
        allow(controller).to receive(:logged_in?).and_return(true)
      end

      it 'does not render unauthorized' do
        expect(controller).not_to receive(:render).with(json: { error: "Please log in." }, status: :unauthorized)
        controller.send(:logged_in_user)
      end
    end

    context 'when the user is not logged in' do
      before do
        allow(controller).to receive(:logged_in?).and_return(false)
      end

      it 'renders unauthorized' do
        expect(controller).to receive(:render).with(json: { error: "Please log in." }, status: :unauthorized)
        controller.send(:logged_in_user)
      end
    end
  end

  describe '#correct_user' do
    let(:other_user) { create(:user) }

    context 'when the user is the correct user' do
      before do
        allow(controller).to receive(:authenticate_user).and_return(true)
        controller.instance_variable_set(:@current_user, user)
        allow(controller).to receive(:current_user).and_return(user)
        allow(User).to receive(:find).with(user.id.to_s).and_return(user)
      end

      it 'allows access' do
        get :show, params: { id: user.id }
        expect(response).to have_http_status(:ok)
      end
    end

    context 'when the user is not the correct user' do
      before do
        allow(controller).to receive(:authenticate_user).and_return(true)
        allow(controller).to receive(:current_user).and_return(other_user)
        allow(User).to receive(:find).with(user.id.to_s).and_return(user)
      end

      it 'returns forbidden' do
        get :show, params: { id: user.id }
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)['error']).to eq('Not authorized.')
      end
    end
  end
end
