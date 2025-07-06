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
      expect(json['rouletteTexts'].map { |rt_json| rt_json['id'] }).to include rt.id
      # tickets
      expect(json['tickets']).to eq 7
    end    

    it 'latestCompletedGoals が 24h 以内の 3 件になること' do
      user  = create(:user)
      goal  = create(:goal, user: user)

      # 24h 以内に完了した SmallGoal を3件
      recent_goals = []
      3.times do |i|
        t = (i + 1).hours.ago
        recent_goals << create(:small_goal,
                               goal: goal,
                               completed: true,
                               completed_time: t,
                               deadline: t + 2.days)
      end

      # 24h より前に完了した SmallGoal を10件
      10.times do |i|
        t = (25 + i).hours.ago
        create(:small_goal,
               goal: goal,
               completed: true,
               completed_time: t,
               deadline: t + 2.days)
      end

      allow(controller).to receive(:authenticate_user).and_return(true)
      controller.instance_variable_set(:@current_user, user)

      get :show
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      latest = json['latestCompletedGoals']
      expect(latest.size).to eq 3

      expected_ids = recent_goals.sort_by(&:completed_time).reverse.map(&:id)
      actual_ids   = latest.map { |g| g['id'] }
      expect(actual_ids).to eq expected_ids
    end

    it '24h 内に完了が無い場合は最新の完了 SmallGoal 10 件が返ること' do
      user = create(:user)
      goal = create(:goal, user: user)

      old_goals = []
      11.times do |i|
        t = (25 + i).hours.ago
        old_goals << create(:small_goal,
                            goal: goal,
                            completed: true,
                            completed_time: t,
                            deadline: t + 2.days)
      end

      allow(controller).to receive(:authenticate_user).and_return(true)
      controller.instance_variable_set(:@current_user, user)

      get :show
      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      latest = json['latestCompletedGoals']
      expect(latest.size).to eq 10

      # newest 10 of old_goals (descending by completed_time)
      expected_ids = old_goals.sort_by(&:completed_time).reverse.map(&:id).first(10)
      actual_ids = latest.map { |g| g['id'] }
      expect(actual_ids).to eq expected_ids
    end

    it 'latestCompletedGoals が completed_time 降順で返ること (7件ケース)' do
      user = create(:user)
      goal = create(:goal, user: user)

      recent = []
      7.times do |i|
        t = (i + 1).hours.ago
        recent << create(:small_goal,
                         goal: goal,
                         completed: true,
                         completed_time: t,
                         deadline: t + 2.days)
      end

      allow(controller).to receive(:authenticate_user).and_return(true)
      controller.instance_variable_set(:@current_user, user)

      get :show
      expect(response).to have_http_status(:ok)

      json   = JSON.parse(response.body)
      latest = json['latestCompletedGoals']
      expect(latest.size).to eq 7

      times = latest.map { |g| g['completed_time'] }
      expect(times).to eq times.sort.reverse
      expect(latest.first['id']).to eq recent.max_by(&:completed_time).id
    end

    it '@current_user が nil の場合は 404 と JSON {error:"User not found"} が返ること' do
      allow(controller).to receive(:authenticate_user).and_return(true)
      controller.instance_variable_set(:@current_user, nil)

      get :show
      expect(response).to have_http_status(:not_found)
      expect(response.content_type).to include('application/json')
      json = JSON.parse(response.body)
      expect(json.keys).to eq(['error'])
      expect(json['error']).to eq('User not found')
    end

    it 'update_rank が成功すると JSON {success:true} かつ DB が更新されること' do
      user = create(:user, last_roulette_rank: 0)

      # 認証フィルタをバイパス
      allow(controller).to receive(:authenticate_user).and_return(true)
      controller.instance_variable_set(:@current_user, user)

      patch :update_rank, params: { id: user.id, new_rank: 7 }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to eq('success' => true, 'message' => 'Rank updated successfully.')

      expect(user.reload.last_roulette_rank).to eq 7
    end

    it 'new_rank が文字列の場合 to_i で 0 がセットされること' do
      user = create(:user, last_roulette_rank: 5)

      allow(controller).to receive(:authenticate_user).and_return(true)
      controller.instance_variable_set(:@current_user, user)

      patch :update_rank, params: { id: user.id, new_rank: 'abc' }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['success']).to be true

      expect(user.reload.last_roulette_rank).to eq 0
    end

    it 'update_rank が失敗すると 422 と JSON {success:false} が返ること' do
      user = create(:user, last_roulette_rank: 1)

      allow(controller).to receive(:authenticate_user).and_return(true)
      controller.instance_variable_set(:@current_user, user)

      # update が false を返すようにスタブ
      allow(user).to receive(:update).and_return(false)

      patch :update_rank, params: { id: user.id, new_rank: 7 }

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json).to eq('success' => false, 'message' => 'Failed to update rank.')
    end

    context '内部で例外が発生した場合' do
      it '@current_user.goals が例外を投げると 500 エラーが発生すること' do
        user = create(:user)

        allow(controller).to receive(:authenticate_user).and_return(true)
        controller.instance_variable_set(:@current_user, user)

        # goals 呼び出しで例外を発生させる
        allow(user).to receive(:goals).and_raise(StandardError.new('DB error'))

        # テスト環境では show_exceptions=false のため直接例外が飛ぶ
        expect do
          get :show
        end.to raise_error(StandardError, 'DB error')
      end
    end
  end

  describe 'PATCH #update' do
    context '認証済みユーザーの場合' do
      let(:user) { create(:user) }

      before do
        allow(controller).to receive(:authenticate_user).and_return(true)
        controller.instance_variable_set(:@current_user, user)
      end

      it 'ユーザーネームが正常に更新されること' do
        patch :update, params: { user: { name: 'New Name' } }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
        expect(json['message']).to eq('User updated successfully.')
        expect(json['user']['name']).to eq('New Name')
        expect(json['user']['id']).to eq(user.id)
        expect(json['user']['email']).to eq(user.email)

        # DB の値も更新されているか確認
        expect(user.reload.name).to eq('New Name')
      end

      it 'バリデーションエラーの場合は422が返ること' do
        patch :update, params: { user: { name: '' } }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
        expect(json['message']).to eq('Failed to update user.')
        expect(json['errors']).to be_present
      end
    end

    context '未認証ユーザーの場合' do
      before do
        request.headers['Authorization'] = nil
      end

      it '401 と JSON {error:"Unauthorized"} が返ること' do
        patch :update, params: { user: { name: 'New Name' } }
        expect(response).to have_http_status(:unauthorized)
        expect(response.content_type).to include('application/json')
        json = JSON.parse(response.body)
        expect(json.keys).to eq(['error'])
        expect(json['error']).to eq('Unauthorized')
      end
    end
  end
end 