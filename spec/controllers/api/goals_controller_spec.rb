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

  describe 'create アクション' do
    let(:valid_params) do
      {
        goal: {
          title: 'New Goal',
          content: 'Goal content',
          deadline: 2.weeks.from_now
        }
      }
    end

    context '認証済みユーザーの場合' do
      before do
        allow(controller).to receive(:authenticate_user).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it '201 Created が返り、Goal が 1 件増え、id とメッセージを含む JSON が返ること' do
        expect do
          post :create, params: valid_params
        end.to change { user.goals.count }.by(1)

        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json.keys).to include('id', 'message')
      end
    end

    context '未認証ユーザーの場合' do
      before do
        # 認証フィルタは通過させるが current_user は nil
        allow(controller).to receive(:authenticate_user).and_return(true)
        allow(controller).to receive(:current_user).and_return(nil)
      end

      it '401 と {error:"ログインが必要です"} が返ること' do
        post :create, params: valid_params

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json).to eq('error' => 'ログインが必要です')
      end
    end

    context 'バリデーションエラーの場合' do
      before do
        allow(controller).to receive(:authenticate_user).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it '422 Unprocessable Entity とエラーメッセージが返ること' do
        invalid_params = {
          goal: {
            title: '',
            content: '',
            deadline: ''
          }
        }

        expect do
          post :create, params: invalid_params
        end.not_to(change { Goal.count })

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json).to be_a(Hash)
        expect(json.keys).to include('title')
      end
    end
  end

  describe 'update アクション' do
    let(:goal) { create(:goal, user: user, title: 'Old Title', content: 'Old content') }

    before do
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end

    context '正常に更新できる場合' do
      let(:update_params) do
        {
          id: goal.id,
          goal: {
            title: 'New Title',
            content: 'Updated content',
            deadline: 3.weeks.from_now
          }
        }
      end

      it '200 OK と更新後 JSON が返り、属性が変更されること' do
        patch :update, params: update_params

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json['title']).to eq 'New Title'
        expect(json['content']).to eq 'Updated content'

        # DB 値も更新されているか確認
        expect(goal.reload.title).to eq 'New Title'
      end
    end

    context 'バリデーション NG の場合' do
      let(:invalid_params) do
        {
          id: goal.id,
          goal: {
            title: '',
            content: '',
            deadline: ''
          }
        }
      end

      it '422 Unprocessable Entity と errors JSON が返ること' do
        patch :update, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json).to be_a(Hash)
        expect(json.keys).to include('title')

        # 値が変更されていないことを確認
        expect(goal.reload.title).to eq 'Old Title'
      end
    end
  end

  # ------------------ complete アクション ------------------
  describe 'complete アクション' do
    before do
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end

    context '小目標が未完了の場合' do
      let(:goal) { create(:goal, user: user) }
      let!(:incomplete_sg) { create(:small_goal, goal: goal, completed: false, deadline: 1.day.from_now) }

      it '422 と {success:false, message:"まだ完了していない小目標があります。"} が返ること' do
        post :complete, params: { id: goal.id }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json).to eq('success' => false, 'message' => 'まだ完了していない小目標があります。')

        expect(goal.reload.completed).to be_falsey
      end
    end

    context '全小目標が完了している場合' do
      let(:user) { create(:user, total_exp: 100, tickets: 0, last_roulette_rank: 0) }
      let(:goal) { create(:goal, user: user) }

      let!(:completed_sg) do
        create(:small_goal,
               goal: goal,
               completed: true,
               difficulty: '普通',
               tasks_count: 2,
               deadline: 1.day.from_now)
      end

      it '200 OK と EXP 付与、Goal.completed true、tickets 増加、Activity 作成' do
        prev_total_exp = user.total_exp
        prev_tickets   = user.tickets

        expect(user).to receive(:update_tickets).and_call_original

        expect do
          post :complete, params: { id: goal.id }
        end.to change { Activity.count }.by(1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['success']).to eq true
        expect(json['message']).to match(/EXP gained: \d+/)

        expect(goal.reload.completed).to be true

        exp_gained = 6 # 2 tasks * 1.0 multiplier * 3
        expect(user.reload.total_exp).to eq(prev_total_exp + exp_gained)

        expect(user.reload.tickets).to be > prev_tickets

        activity = Activity.last
        expect(activity.exp_gained).to eq exp_gained
        expect(activity.goal_id).to eq goal.id
        expect(activity.user_id).to eq user.id
      end
    end

    context 'id が存在しない場合' do
      before do
        allow(controller).to receive(:set_goal) do
          controller.instance_variable_set(:@goal, nil)
        end
      end

      it '404 と {error:"Goal not found"} が返ること' do
        post :complete, params: { id: 0 }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json).to eq('error' => 'Goal not found')
      end
    end
  end

  # ------------------ destroy アクション ------------------
  describe 'destroy アクション' do
    before do
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end

    context '自分の Goal を削除する場合' do
      let!(:goal) { create(:goal, user: user) }

      it '200 OK と削除メッセージが返り、レコードが 1 件減ること' do
        expect do
          delete :destroy, params: { id: goal.id }
        end.to change { user.goals.count }.by(-1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to eq 'Goal was successfully deleted.'
      end
    end

    context '他ユーザーの Goal id を指定した場合' do
      let(:other_goal) { create(:goal) }

      around do |example|
        original = Rails.application.config.action_dispatch.show_exceptions
        Rails.application.config.action_dispatch.show_exceptions = true
        example.run
        Rails.application.config.action_dispatch.show_exceptions = original
      end

      it 'ActiveRecord::RecordNotFound が発生すること (404 相当)' do
        expect do
          delete :destroy, params: { id: other_goal.id }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  # ------------------ Strong Parameters (goal_params / small_goal_params) ------------------
  describe 'Strong Parameters' do
    before do
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end

    context 'create 時に想定外キーが含まれていた場合' do
      let(:other_user) { create(:user) }
      let(:params_with_extra) do
        {
          goal: {
            title: 'Param Test',
            content: 'Content',
            deadline: 1.week.from_now,
            user_id: other_user.id,        # ← 本来許可されない
            completed: true                # ← 許可されない
          }
        }
      end

      it 'user_id や completed は無視され、goal は current_user 所有・completed=false で作成されること' do
        post :create, params: params_with_extra

        expect(response).to have_http_status(:created)

        goal_id = JSON.parse(response.body)['id']
        created_goal = Goal.find(goal_id)

        expect(created_goal.user_id).to eq user.id
        expect(created_goal.completed).to be_falsey
      end
    end

    context 'update 時に想定外キーが含まれていた場合' do
      let!(:goal) { create(:goal, user: user, completed: false) }
      let(:other_user) { create(:user) }

      let(:update_params_with_extra) do
        {
          id: goal.id,
          goal: {
            title: 'Keep Me',
            user_id: other_user.id,  # 許可されない
            completed: true          # 許可されない
          }
        }
      end

      it 'user_id や completed は変更されず、title だけが更新されること' do
        patch :update, params: update_params_with_extra

        expect(response).to have_http_status(:ok)

        goal.reload
        expect(goal.title).to eq 'Keep Me'
        expect(goal.user_id).to eq user.id
        expect(goal.completed).to be_falsey
      end
    end
  end

  # ------------------ calculate_exp_for_small_goal (private method) ------------------
  describe '#calculate_exp_for_small_goal (private method)' do
    before do
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end

    it 'tasks の数 × 難易度係数を 1 桁丸めで返すこと' do
      sg = create(:small_goal, difficulty: '難しい', tasks_count: 3) # multiplier 1.2

      exp = controller.send(:calculate_exp_for_small_goal, sg)

      expect(exp).to eq((3 * 1.2).round(1)) # 3.6
    end

    it '定義外難易度の場合は係数 1.0 で計算されること' do
      sg = create(:small_goal, difficulty: '未知', tasks_count: 2)

      exp = controller.send(:calculate_exp_for_small_goal, sg)

      expect(exp).to eq((2 * 1.0).round(1)) # 2.0
    end
  end
end