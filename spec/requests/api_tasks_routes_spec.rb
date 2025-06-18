require 'rails_helper'

RSpec.describe 'API Tasks routes', type: :request do
  describe 'HTTP メソッド制限' do
    let!(:task) { create(:task) }
    let(:path)  { "/api/tasks/#{task.id}/complete" }

    it 'POST は成功だが GET は RoutingError (No route)' do
      post path, params: { completed: true }
      expect(response).to have_http_status(:ok).or have_http_status(:success)

      expect do
        get path
      end.to raise_error(ActionController::RoutingError)
    end

    it 'PATCH は RoutingError になること' do
      expect do
        patch path, params: { completed: true }
      end.to raise_error(ActionController::RoutingError)
    end
  end
end