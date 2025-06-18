require 'rails_helper'

RSpec.describe Api::SmallGoalsController, type: :controller do
  let(:user)  { create(:user) }
  let(:goal)  { create(:goal, user: user) }

  shared_examples 'calls authenticate_user' do |http_method, action, params = {}|
    it "#{http_method.upcase} #{action} で authenticate_user が呼ばれること" do
      expect(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)

      case http_method
      when :get
        get action, params: params.merge(goal_id: goal.id)
      when :post
        post action, params: params.merge(goal_id: goal.id)
      when :patch
        patch action, params: params.merge(goal_id: goal.id, id: params[:id])
      when :delete
        delete action, params: params.merge(goal_id: goal.id, id: params[:id])
      end
    end
  end

  # index と create で確認
  include_examples 'calls authenticate_user', :get, :index
  include_examples 'calls authenticate_user', :post, :create, { small_goal: { title: 't', difficulty: '普通', deadline: 1.day.from_now } }

  # OPTIONS メソッドでは authenticate_user が呼ばれない
  describe 'OPTIONS リクエスト' do
    it 'authenticate_user が呼ばれないこと' do
      expect(controller).not_to receive(:authenticate_user)

      allow(controller).to receive(:current_user).and_return(user)

      process :index, method: :options, params: { goal_id: goal.id }
      expect([200, 204]).to include(response.status)
    end
  end

  # ------------------ スコープ制限 (current_user.goals 内) ------------------
  describe 'スコープ: 他ユーザーの goal_id / small_goal へのアクセス' do
    let(:other_user)  { create(:user) }
    let(:other_goal)  { create(:goal, user: other_user) }
    let(:other_small) { create(:small_goal, goal: other_goal) }

    before do
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end

    context 'index アクションで他ユーザーの goal_id を指定した場合' do
      it 'ActiveRecord::RecordNotFound が発生すること' do
        expect do
          get :index, params: { goal_id: other_goal.id }   # ← current_user でない Goal
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'show アクションで他ユーザーの small_goal id を指定した場合' do
      it 'ActiveRecord::RecordNotFound が発生すること' do
        expect do
          get :show, params: { goal_id: other_goal.id, id: other_small.id }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  # ------------------ index アクションのレスポンス内容 ------------------
  describe 'index アクション' do
    let(:user) { create(:user) }
    let(:goal) { create(:goal, user: user) }

    before do
      # small_goals with varying task counts
      @sg1 = create(:small_goal, goal: goal, tasks_count: 2, deadline: 1.day.from_now)
      @sg2 = create(:small_goal, goal: goal, tasks_count: 3, deadline: 2.days.from_now)

      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end

    it 'tasks がネストされ、件数が DB 件数と一致すること' do
      get :index, params: { goal_id: goal.id }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json.length).to eq goal.small_goals.count

      sg1_json = json.find { |sg| sg['id'] == @sg1.id }
      sg2_json = json.find { |sg| sg['id'] == @sg2.id }

      expect(sg1_json['tasks'].length).to eq @sg1.tasks.count
      expect(sg2_json['tasks'].length).to eq @sg2.tasks.count
    end
  end

  # ------------------ show アクション ------------------
  describe 'show アクション' do
    let(:user) { create(:user) }
    let(:goal) { create(:goal, user: user) }
    let!(:small_goal) { create(:small_goal, goal: goal, tasks_count: 2, deadline: 1.day.from_now) }

    before do
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end

    it '正しい goal_id と id で 200 と詳細 JSON が返り tasks が配列である' do
      get :show, params: { goal_id: goal.id, id: small_goal.id }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq small_goal.id
      expect(json['tasks']).to be_an(Array)
      expect(json['tasks'].length).to eq small_goal.tasks.count
    end

    context '他ユーザーの small_goal を指定した場合' do
      let(:other_user) { create(:user) }
      let(:other_goal) { create(:goal, user: other_user) }
      let(:other_small) { create(:small_goal, goal: other_goal) }

      it 'ActiveRecord::RecordNotFound が発生し 404 相当になる' do
        expect do
          get :show, params: { goal_id: other_goal.id, id: other_small.id }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  # ------------------ create アクション ------------------
  describe 'create アクション' do
    let(:user) { create(:user) }
    let(:goal) { create(:goal, user: user) }

    before do
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end

    context '正常パラメータの場合' do
      let(:valid_params) do
        {
          goal_id: goal.id,
          small_goal: {
            title: 'New SmallGoal',
            difficulty: '普通',
            deadline: 3.days.from_now,
            tasks_attributes: [{ content: 'task1' }]
          }
        }
      end

      it '201 Created, small_goals 件数 +1, Owner が current_user である' do
        expect do
          post :create, params: valid_params
        end.to change { goal.small_goals.count }.by(1)

        expect(response).to have_http_status(:created)

        json = JSON.parse(response.body)
        expect(json['message']).to be_present

        created_sg = goal.small_goals.order(:created_at).last
        expect(created_sg.title).to eq 'New SmallGoal'
        expect(created_sg.goal.user_id).to eq user.id
      end
    end

    context 'バリデーションエラーの場合' do
      let(:invalid_params) do
        {
          goal_id: goal.id,
          small_goal: {
            title: '',
            difficulty: '普通',
            deadline: 3.days.from_now,
            tasks_attributes: [{ content: 'task1' }]
          }
        }
      end

      it '422 Unprocessable Entity と errors 配列を返す' do
        expect do
          post :create, params: invalid_params
        end.not_to(change { goal.small_goals.count })

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['errors']).to be_an(Array)
        expect(json['errors']).not_to be_empty
      end
    end
  end

  # ------------------ update アクション ------------------
  describe 'update アクション' do
    let(:user) { create(:user) }
    let(:goal) { create(:goal, user: user) }
    let!(:small_goal) { create(:small_goal, goal: goal, title: 'Old', difficulty: '普通', deadline: 2.days.from_now, tasks_count: 2) }

    before do
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end

    context '属性の更新が成功する場合' do
      let(:new_deadline) { 5.days.from_now }
      let(:params) do
        {
          goal_id: goal.id,
          id: small_goal.id,
          small_goal: {
            title: 'Updated',
            difficulty: '難しい',
            deadline: new_deadline
          }
        }
      end

      it '200 OK と共に title / difficulty / deadline が更新される' do
        patch :update, params: params

        expect(response).to have_http_status(:ok)

        small_goal.reload
        expect(small_goal.title).to eq 'Updated'
        expect(small_goal.difficulty).to eq '難しい'
        expect(small_goal.deadline.to_i).to eq new_deadline.to_i
      end
    end

    context 'tasks_attributes で _destroy:true を指定した場合' do
      let!(:task_to_remove) { small_goal.tasks.first }
      let(:params) do
        {
          goal_id: goal.id,
          id: small_goal.id,
          small_goal: {
            title: small_goal.title,
            difficulty: small_goal.difficulty,
            deadline: small_goal.deadline,
            tasks_attributes: [
              { id: task_to_remove.id, _destroy: true }
            ]
          }
        }
      end

      it 'タスクが削除されること' do
        expect do
          patch :update, params: params
        end.to change { small_goal.tasks.count }.by(-1)

        expect(response).to have_http_status(:ok)
        expect(Task.exists?(task_to_remove.id)).to be_falsey
      end
    end

    context 'バリデーションエラーの場合' do
      let(:bad_params) do
        {
          goal_id: goal.id,
          id: small_goal.id,
          small_goal: {
            title: '',
            difficulty: '',
            deadline: ''
          }
        }
      end

      it '422 Unprocessable Entity と errors を返す' do
        patch :update, params: bad_params

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json).to be_a(Hash)
        expect(json.keys).to include('title').or include('difficulty')
      end
    end
  end

  # ------------------ destroy アクション ------------------
  describe 'destroy アクション' do
    let(:user) { create(:user) }
    let(:goal) { create(:goal, user: user) }
    let!(:small_goal) { create(:small_goal, goal: goal) }

    before do
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end

    context '自分の small_goal を削除する場合' do
      it '200 OK が返り、レコードが削除されること' do
        expect do
          delete :destroy, params: { goal_id: goal.id, id: small_goal.id }
        end.to change { goal.small_goals.count }.by(-1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['status']).to eq 'success'
        expect(json['message']).to include 'deleted'

        expect(SmallGoal.exists?(small_goal.id)).to be_falsey
      end
    end

    context '他ユーザーの small_goal を指定した場合' do
      let(:other_user) { create(:user) }
      let(:other_goal) { create(:goal, user: other_user) }
      let!(:other_small) { create(:small_goal, goal: other_goal) }

      it 'ActiveRecord::RecordNotFound が発生すること' do
        expect do
          delete :destroy, params: { goal_id: other_goal.id, id: other_small.id }
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  # ------------------ complete アクション ------------------
  describe 'complete アクション' do
    let(:user) { create(:user, total_exp: 0) }
    let(:goal) { create(:goal, user: user) }
    let!(:small_goal) { create(:small_goal, goal: goal, completed: false, difficulty: '普通', tasks_count: 2) }

    before do
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end

    context '初回完了の場合' do
      it '200 success, EXP 加算, Activity 作成' do
        prev_exp = user.total_exp

        expected_exp = (small_goal.tasks.count * 1.0).round # difficulty 普通 = 1.0

        expect do
          post :complete, params: { goal_id: goal.id, id: small_goal.id }
        end.to change { Activity.count }.by(1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['status']).to eq 'success'
        expect(json['exp_gained']).to eq expected_exp

        expect(user.reload.total_exp).to eq(prev_exp + expected_exp)
      end

      it 'current_user の use_ticket や update_tickets が呼ばれないこと' do
        allow(user).to receive(:use_ticket)
        allow(user).to receive(:update_tickets)

        post :complete, params: { goal_id: goal.id, id: small_goal.id }

        expect(user).not_to have_received(:use_ticket)
        expect(user).not_to have_received(:update_tickets)
      end
    end

    context 'update が false を返す場合' do
      before do
        allow_any_instance_of(SmallGoal).to receive(:update).and_return(false)
      end

      it '422 と error JSON を返す' do
        post :complete, params: { goal_id: goal.id, id: small_goal.id }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['status']).to eq 'error'
      end
    end
  end

  # ------------------ calculate_exp_for_small_goal (private) ------------------
  describe '#calculate_exp_for_small_goal (private)' do
    let(:user) { create(:user) }
    let(:goal) { create(:goal, user: user) }

    before do
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end

    it "tasks × 難易度係数を 1 桁丸めで返す (難しい, 3 タスク → 3.6)" do
      sg = create(:small_goal, goal: goal, difficulty: '難しい', tasks_count: 3)

      exp = controller.send(:calculate_exp_for_small_goal, sg)

      expect(exp).to eq((3 * 1.2).round(1)) # 3.6
    end

    it '未知の難易度は係数 1.0 で計算される' do
      sg = create(:small_goal, goal: goal, difficulty: 'UNKNOWN', tasks_count: 4)

      exp = controller.send(:calculate_exp_for_small_goal, sg)

      expect(exp).to eq((4 * 1.0).round(1))
    end
  end

  # ------------------ Strong Parameters ------------------
  describe 'Strong Parameters (create)' do
    let(:user) { create(:user) }
    let(:goal) { create(:goal, user: user) }

    before do
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(user)
    end

    it '許可されていないキーは無視される (hacker キー)' do
      params = {
        goal_id: goal.id,
        small_goal: {
          title: 'Sec Test',
          difficulty: '普通',
          deadline: 1.day.from_now,
          tasks_attributes: [{ content: 'task' }],
          hacker: 'evil'
        }
      }

      post :create, params: params

      expect(response).to have_http_status(:created)

      sg = goal.small_goals.order(:created_at).last
      expect(sg.title).to eq 'Sec Test'
      expect(sg.attributes).not_to have_key('hacker')
    end
  end
end 