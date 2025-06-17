require 'rails_helper'

RSpec.describe Api::CurrentUsersController, type: :controller do
  describe 'before_action :authenticate_user' do
    it 'authenticate_user フィルタが実行されること (show)' do
      expect(controller).to receive(:authenticate_user).and_call_original
      get :show
    end

    it 'authenticate_user フィルタが実行されること (update_rank)' do
      expect(controller).to receive(:authenticate_user).and_call_original
      post :update_rank, params: { id: 1, new_rank: 5 }
    end
  end

  describe '未認証ユーザーの場合' do
    before do
      # Authorization ヘッダーを付与しない (Bearer トークンなし)
      request.headers['Authorization'] = nil
    end

    it 'show アクションで 401 と JSON {error:"Unauthorized"} が返ること' do
      get :show
      expect(response).to have_http_status(:unauthorized)
      expect(response.content_type).to include('application/json')
      json = JSON.parse(response.body)
      expect(json.keys).to eq(['error'])
      expect(json['error']).to eq('Unauthorized')
    end

    it 'update_rank アクションで 401 と JSON {error:"Unauthorized"} が返ること' do
      post :update_rank, params: { id: 1, new_rank: 5 }
      expect(response).to have_http_status(:unauthorized)
      expect(response.content_type).to include('application/json')
      json = JSON.parse(response.body)
      expect(json.keys).to eq(['error'])
      expect(json['error']).to eq('Unauthorized')
    end
  end

  describe 'OPTIONS リクエスト' do
    it 'show アクションで authenticate_user が呼ばれず 200/204 が返ること' do
      expect(controller).not_to receive(:authenticate_user)
    
      user = create(:user)
      # インスタンス変数を直接セット
      controller.instance_variable_set(:@current_user, user)
    
      process :show, method: :options
      expect([200, 204]).to include(response.status)
    end    
  end

  describe '@current_user が存在する場合' do
    it 'show アクションが 200 OK を返すこと' do
      user = create(:user)

      # 認証フィルタをバイパス
      allow(controller).to receive(:authenticate_user).and_return(true)

      # @current_user を直接セット
      controller.instance_variable_set(:@current_user, user)

      get :show
      expect(response).to have_http_status(:ok)

      # 基本情報の JSON 構造を確認
      json = JSON.parse(response.body)
      expect(json).to include(
        'id' => user.id,
        'name' => user.name,
        'email' => user.email
      )

      %w[totalExp rank last_roulette_rank].each do |key|
        expect(json.keys).to include(key)
      end
    end

    it '関連リソースが埋め込まれる (goals/small_goals, tasks, rouletteTexts, tickets)' do
      user  = create(:user, tickets: 7)
      goal  = create(:goal, user: user)
      small_goal = create(:small_goal, goal: goal, deadline: 1.day.from_now)
    
      task  = create(:task,  small_goal: small_goal)
    
      rt    = user.roulette_texts.first
    
      allow(controller).to receive(:authenticate_user).and_return(true)
      controller.instance_variable_set(:@current_user, user)
    
      get :show
      expect(response).to have_http_status(:ok)
    
      json = JSON.parse(response.body)
    
      # goals / small_goals
      expect(json['goals'][0]['small_goals'][0]['id']).to eq small_goal.id
      # tasks
      expect(json['tasks'].map { |t| t['id'] }).to include task.id
      # rouletteTexts
      expect(json['rouletteTexts'].map { |rt| rt['id'] }).to include rt.id
      # tickets
      expect(json['tickets']).to eq 7
    end    
  end
end 