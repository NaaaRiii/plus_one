require 'rails_helper'

RSpec.describe Api::UsersController, type: :controller do
  let(:user) { create(:user) }

  # テスト用に API::UsersController のシンプルなルートを定義
  before(:all) do
    Rails.application.routes.draw do
      namespace :api do
        get 'users/:id', to: 'users#show'
        match 'users/:id', to: 'users#show', via: :options # OPTIONS も許可
        delete 'users/withdrawal', to: 'users#withdrawal'
      end
    end
  end

  after(:all) do
    Rails.application.reload_routes!
  end

  describe 'before_action :authenticate_user' do
    context '通常の GET /show リクエスト' do
      it 'authenticate_user フィルタが呼ばれること' do
        # authenticate_user をスパイ化
        expect(controller).to receive(:authenticate_user).and_return(true)

        get :show, params: { id: user.id }
      end
    end

    context 'OPTIONS リクエスト' do
      it 'authenticate_user が呼ばれず 200/204 が返ること' do
        expect(controller).not_to receive(:authenticate_user)

        # OPTIONS リクエストを送信
        process :show, method: :options, params: { id: user.id }

        expect([200, 204]).to include(response.status)
      end
    end
  end

  describe 'before_action :find_current_user' do
    it '@current_user に params[:id] に一致する User がセットされること' do
      # 認証フィルタは通過させる
      allow(controller).to receive(:authenticate_user).and_return(true)

      get :show, params: { id: user.id }

      assigned_user = controller.instance_variable_get(:@current_user)
      expect(assigned_user).to eq(user)
    end
  end

  # 正常系 (200 OK) のテスト群
  describe '正常系 (200 OK)' do
    before do
      # 認証を通過させる
      allow(controller).to receive(:authenticate_user).and_return(true)
    end

    it 'ステータス 200 / JSON 構造 / calculate_rank 呼び出し' do
      # calculate_rank が呼ばれることを検証
      expect_any_instance_of(User).to receive(:calculate_rank).and_call_original

      get :show, params: { id: user.id }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')

      json = JSON.parse(response.body)
      %w[name totalExp rank tickets latestCompletedGoals].each do |key|
        expect(json.keys).to include(key)
      end

      # 数値型で返ること
      expect(json['totalExp']).to be_a(Numeric)
      expect(json['tickets']).to be_a(Integer)
    end

    describe 'latestCompletedGoals の選択ロジック' do
      let!(:goal) { create(:goal, user: user) }

      it '24h 以内に完了した小目標があればそれが最大10件返ること' do
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

        # rank 計算は呼ばれるが値は任意で良いのでスタブ
        allow_any_instance_of(User).to receive(:calculate_rank).and_return(1)

        get :show, params: { id: user.id }

        expect(response).to have_http_status(:ok)

        json   = JSON.parse(response.body)
        latest = json['latestCompletedGoals']
        expect(latest.size).to eq 3

        expected_ids = recent_goals.sort_by(&:completed_time).reverse.map(&:id)
        actual_ids   = latest.map { |g| g['id'] }
        expect(actual_ids).to eq expected_ids

        # 各項目のキーが id, title, completed_time だけであること
        latest.each do |g|
          expect(g.keys.sort).to eq(%w[completed_time id title])
        end
      end

      it '24h 内に完了が無い場合は最新完了順で最大10件返ること' do
        # 24h より前に完了した SmallGoal を11件
        old_goals = []
        11.times do |i|
          t = (25 + i).hours.ago
          old_goals << create(:small_goal,
                              goal: goal,
                              completed: true,
                              completed_time: t,
                              deadline: t + 2.days)
        end

        allow_any_instance_of(User).to receive(:calculate_rank).and_return(1)

        get :show, params: { id: user.id }

        expect(response).to have_http_status(:ok)

        json   = JSON.parse(response.body)
        latest = json['latestCompletedGoals']
        expect(latest.size).to eq 10

        expected_ids = old_goals.sort_by(&:completed_time).reverse.map(&:id).first(10)
        actual_ids   = latest.map { |g| g['id'] }
        expect(actual_ids).to eq expected_ids

        latest.each do |g|
          expect(g.keys.sort).to eq(%w[completed_time id title])
        end
      end

      it '小目標が 0 件でも latestCompletedGoals が [] で 200 が返ること' do
        allow_any_instance_of(User).to receive(:calculate_rank).and_return(1)

        get :show, params: { id: user.id }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['latestCompletedGoals']).to eq([])
      end

      it '小目標が 1 件で 24h 超過している場合はその小目標が返ること' do
        old_goal = create(:small_goal,
                          goal: goal,
                          completed: true,
                          completed_time: 2.days.ago,
                          deadline: 1.day.from_now)

        allow_any_instance_of(User).to receive(:calculate_rank).and_return(1)

        get :show, params: { id: user.id }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        latest = json['latestCompletedGoals']
        expect(latest.size).to eq 1
        expect(latest.first['id']).to eq old_goal.id
      end
    end
  end

  # 異常系テスト
  describe '異常系' do
    context '@current_user が見つからない場合' do
      it '404 と {error:"User not found"} が返ること' do
        allow(controller).to receive(:authenticate_user).and_return(true)

        # 存在しない id を指定
        get :show, params: { id: 0 }

        expect(response).to have_http_status(:not_found)
        expect(response.content_type).to include('application/json')

        json = JSON.parse(response.body)
        expect(json).to eq('error' => 'User not found')
      end
    end

    context 'authenticate_user が失敗した場合' do
      it '401 と {error:"Unauthorized"} が返ること' do
        # Authorization ヘッダー無し → authenticate_user が render_unauthorized
        get :show, params: { id: user.id }

        expect(response).to have_http_status(:unauthorized)
        expect(response.content_type).to include('application/json')

        json = JSON.parse(response.body)
        expect(json).to eq('error' => 'Unauthorized')
      end
    end

    context '他ユーザーの id を指定した場合' do
      it '404 と {error:"User not found"} が返ること' do
        other_user = create(:user)

        # authenticate_user を通過させつつ token のユーザーを user に固定
        allow(controller).to receive(:authenticate_user) do
          controller.instance_variable_set(:@current_user, user)
        end

        get :show, params: { id: other_user.id }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json).to eq('error' => 'User not found')
      end
    end
  end

  describe 'DELETE #withdrawal' do
    context '認証済みユーザーの場合' do
      before do
        # authenticate_userを通過させ、@current_userを設定
        allow(controller).to receive(:authenticate_user) do
          controller.instance_variable_set(:@current_user, user)
        end
      end

      it '正常に退会処理が完了する' do
        delete :withdrawal

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('application/json')

        # ユーザーが削除されていることを確認
        expect(User.find_by(id: user.id)).to be_nil
        
        json = JSON.parse(response.body)
        expect(json['status']).to eq('success')
        expect(json['message']).to eq('ユーザーの退会処理が完了しました')
      end

      it '関連データも削除される' do
        # テストデータ作成
        goal = create(:goal, user: user)
        small_goal = create(:small_goal, goal: goal)
        # small_goal のファクトリでデフォルトで1件以上のタスクが紐づく場合があるため
        # ここでの追加作成は行わない（削除件数の揺らぎを避ける）
        activity = create(:activity, user: user)

        # 関連削除の検証（存在ベースで確認）
        delete :withdrawal

        # 各関連データが削除されていることを確認
        expect(User.find_by(id: user.id)).to be_nil
        expect(Goal.exists?(user: user)).to be_falsey
        expect(SmallGoal.joins(:goal).where(goals: { user: user })).to be_empty
        expect(Activity.exists?(user: user)).to be_falsey
        expect(RouletteText.exists?(user: user)).to be_falsey

        expect(response).to have_http_status(:ok)
      end

      it 'ログが出力される' do
        allow(Rails.logger).to receive(:info)

        delete :withdrawal

        expect(Rails.logger).to have_received(:info)
          .with("User withdrawal completed: user_id=#{user.id}")
      end

      context '削除に失敗した場合' do
        it 'エラーレスポンスが返される' do
          allow_any_instance_of(User).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed.new('削除失敗'))
          expect(Rails.logger).to receive(:error).with(/User withdrawal failed/)

          delete :withdrawal

          expect(response).to have_http_status(:internal_server_error)
          json = JSON.parse(response.body)
          expect(json['status']).to eq('error')
          expect(json['error']).to eq('退会処理中にエラーが発生しました')
        end
      end
    end

    context '未認証ユーザーの場合' do
      it '401エラーが返される' do
        # authenticate_userが失敗する場合をシミュレート
        delete :withdrawal

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Unauthorized')
      end
    end

    context '@current_userが設定されていない場合' do
      before do
        allow(controller).to receive(:authenticate_user).and_return(true)
        # @current_userを意図的にnilにする
        controller.instance_variable_set(:@current_user, nil)
      end

      it '401エラーが返される' do
        delete :withdrawal

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Unauthorized')
      end
    end
  end
end 