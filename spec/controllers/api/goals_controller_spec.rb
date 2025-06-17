require 'rails_helper'

RSpec.describe Api::GoalsController, type: :controller do
  let(:user) { create(:user) }

  shared_examples 'calls authenticate_user' do |http_method, action, params = {}|
    it "#{http_method.upcase} #{action} で authenticate_user が呼ばれること" do
      expect(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)

      case http_method
      when :get
        get action, params: params
      when :post
        post action, params: params
      when :patch
        patch action, params: params
      when :delete
        delete action, params: params
      end
    end
  end

  # 非OPTIONS リクエストでフィルタが呼ばれる
  include_examples 'calls authenticate_user', :get, :index
  include_examples 'calls authenticate_user', :post, :create, { goal: { title: 't', content: 'c', deadline: 1.day.from_now } }

  # OPTIONS では呼ばれない
  describe 'OPTIONS リクエスト' do
    it 'authenticate_user が呼ばれないこと' do
      expect(controller).not_to receive(:authenticate_user)

      # current_user をスタブして NilClass エラーを防ぐ
      allow(controller).to receive(:current_user).and_return(user)

      process :index, method: :options
      expect([200, 204]).to include(response.status)
    end
  end

  describe 'show アクション' do
    before do
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end

    it 'current_user の Goal を取得し small_goals→tasks までネストされて返ること' do
      goal = create(:goal, user: user)
      sg   = create(:small_goal, goal: goal, deadline: 1.day.from_now)
      task = create(:task, small_goal: sg)

      get :show, params: { id: goal.id }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(goal.id)
      expect(json['small_goals'][0]['id']).to eq(sg.id)
      #expect(json['small_goals'][0]['tasks'][0]['id']).to eq(task.id)
      task_ids = json['small_goals'][0]['tasks'].map { |t| t['id'] }
      expect(task_ids).to include(task.id)
      #expect(json).to include('completed_time')
    end

    it '他ユーザーの Goal id を指定すると 404 が返ること' do
      other_goal = create(:goal) # 別ユーザー

      # set_goal before_action が @goal = nil になるようにスタブ
      allow(controller).to receive(:set_goal) do
        controller.instance_variable_set(:@goal, nil)
      end

      get :show, params: { id: other_goal.id }

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json).to eq('error' => 'Goal not found')
    end
  end
end 