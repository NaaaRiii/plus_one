require 'rails_helper'

RSpec.describe Api::RouletteTextsController, type: :controller do
  let(:user) { create(:user) }

  # 共通例: OPTIONS 以外のリクエストで authenticate_user が呼ばれる
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

  # 非 OPTIONS リクエストでフィルタが呼ばれる (例: index)
  include_examples 'calls authenticate_user', :get, :index

  # OPTIONS メソッドではフィルタがスキップされる
  describe 'OPTIONS リクエスト' do
    it 'authenticate_user が呼ばれないこと' do
      expect(controller).not_to receive(:authenticate_user)

      # current_user をスタブして NilClass エラーを防ぐ
      allow(controller).to receive(:current_user).and_return(user)

      process :index, method: :options
      expect([200, 204]).to include(response.status)
    end
  end

  # ------------------ index アクション ------------------
  describe 'index アクション' do
    let!(:current_user) { create(:user) }
    let!(:other_user)   { create(:user) }

    before do
      # current_user にはデフォルトの roulette_texts が12件作成される (after_create コールバック)
      # other_user にも作成されるが、レスポンスには含めないことを検証する
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(current_user)
    end

    it '現在のユーザーの roulette_texts のみを返すこと' do
      get :index

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      ids_from_response = json.map { |rt| rt['id'] }

      expect(json.length).to eq current_user.roulette_texts.count
      expect(ids_from_response).to all(be_in(current_user.roulette_texts.ids))
      # Ensure other_user ids are not present
      expect(ids_from_response & other_user.roulette_texts.ids).to be_empty
    end
  end

  # ------------------ show アクション ------------------
  describe 'show アクション' do
    let!(:current_user) { create(:user) }
    let!(:other_user)   { create(:user) }

    before do
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(current_user)
    end

    context '該当 number が current_user に存在する場合' do
      let(:number) { 3 }

      it '200 OK と該当 JSON が返ること' do
        get :show, params: { number: number }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['number']).to eq number
        expect(json['user_id']).to eq current_user.id
      end
    end

    context 'current_user に該当 number が存在しない場合' do
      let(:absent_number) { 99 }

      it '404 とエラーメッセージが返ること' do
        get :show, params: { number: absent_number }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json).to eq('error' => 'Roulette text not found')
      end
    end

    context '他ユーザーのレコードを指定した場合' do
      let(:exclusive_number) { 12 }

      before do
        # current_user から同じ number を削除し、他ユーザーの番号のみが残る状態にする
        current_user.roulette_texts.find_by(number: exclusive_number).destroy
      end

      it '404 が返ること' do
        get :show, params: { number: exclusive_number }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json).to eq('error' => 'Roulette text not found')
      end
    end
  end

  # ------------------ create アクション ------------------
  describe 'create アクション' do
    let!(:current_user) { create(:user) }

    before do
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(current_user)
    end

    context '正常パラメータの場合' do
      before do
        # 使用予定の number を空けておく
        current_user.roulette_texts.find_by(number: 12).destroy
      end

      let(:params) do
        {
          roulette_text: {
            number: 12,
            text: 'Custom text'
          }
        }
      end

      it '201 Created, レコードが 1 件増え current_user 所有である' do
        expect do
          post :create, params: params
        end.to change { RouletteText.count }.by(1)

        expect(response).to have_http_status(:created)

        new_rt = RouletteText.order(:created_at).last
        expect(new_rt.user_id).to eq current_user.id
        expect(new_rt.number).to eq 12
        expect(new_rt.text).to eq 'Custom text'
      end
    end

    context 'バリデーション NG の場合' do
      let(:invalid_params) do
        {
          roulette_text: {
            number: 13,   # inclusion outside 1..12
            text: ''      # blank text
          }
        }
      end

      it '422 と errors JSON が返る' do
        expect do
          post :create, params: invalid_params
        end.not_to(change { RouletteText.count })

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        # keys should include attribute names with errors
        expect(json.keys).to include('number').or include('text')
      end
    end
  end

  # ------------------ destroy アクション ------------------
  describe 'destroy アクション' do
    let!(:current_user) { create(:user) }
    let!(:other_user)   { create(:user) }

    before do
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(current_user)
    end

    context '自分のレコードを削除する場合' do
      let!(:rt) { current_user.roulette_texts.first }

      it '204 No Content が返り、レコードが削除される' do
        expect do
          delete :destroy, params: { number: rt.number }
        end.to change { current_user.roulette_texts.count }.by(-1)

        expect(response).to have_http_status(:no_content)
        expect(RouletteText.exists?(rt.id)).to be_falsey
      end
    end

    context '他ユーザーのレコード番号を指定した場合' do
      let!(:other_rt) { other_user.roulette_texts.first }

      before do
        # current_user が同じ number を持っていれば削除しておく
        current_user.roulette_texts.find_by(number: other_rt.number)&.destroy
      end

      it '404 と JSON エラーが返る' do
        delete :destroy, params: { number: other_rt.number }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json).to eq('error' => 'Roulette text not found')
      end
    end
  end

  # ------------------ tickets アクション ------------------
  describe 'tickets アクション' do
    let(:user) { create(:user, tickets: 7) }

    context '認証済みユーザーの場合' do
      before do
        allow(controller).to receive(:authenticate_user).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it '200 OK と tickets フィールドが返ること' do
        get :tickets

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['tickets']).to eq user.tickets
      end
    end

    context '未認証ユーザーの場合' do
      before do
        # 認証は通るが current_user は nil
        allow(controller).to receive(:authenticate_user).and_return(true)
        allow(controller).to receive(:current_user).and_return(nil)
      end

      it '401 Unauthorized とエラーメッセージが返ること' do
        get :tickets

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json).to eq('error' => 'User not authenticated')
      end
    end
  end

  # ------------------ spin アクション ------------------
  describe 'spin アクション' do
    context 'チケットがある場合 (use_ticket が true)' do
      let(:user) { create(:user, tickets: 3) }

      before do
        allow(controller).to receive(:authenticate_user).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'use_ticket が呼ばれ、tickets が 1 減り 200 OK が返る' do
        expect(user).to receive(:use_ticket).and_call_original

        expect do
          post :spin
        end.to change { user.reload.tickets }.by(-1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['message']).to include('ルーレット')
        expect(json['tickets']).to eq user.tickets
      end
    end

    context 'チケット不足の場合 (use_ticket が false)' do
      let(:user) { create(:user, tickets: 0) }

      before do
        allow(controller).to receive(:authenticate_user).and_return(true)
        allow(controller).to receive(:current_user).and_return(user)
      end

      it '403 Forbidden とエラーメッセージが返る' do
        expect(user).to receive(:use_ticket).and_call_original

        expect do
          post :spin
        end.not_to(change { user.reload.tickets })

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json).to eq('error' => 'チケット不足', 'tickets' => user.tickets)
      end
    end
  end

  # ------------------ Strong Parameters (create) ------------------
  describe 'Strong Parameters for create' do
    let(:current_user) { create(:user) }
    let(:other_user)   { create(:user) }

    before do
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:current_user).and_return(current_user)
      # ensure number 12 free
      current_user.roulette_texts.find_by(number: 12)&.destroy
    end

    it 'number, text 以外のキーは無視されること' do
      params = {
        roulette_text: {
          number: 12,
          text: 'Strong param test',
          user_id: other_user.id,
          created_at: 3.days.ago
        }
      }

      post :create, params: params

      expect(response).to have_http_status(:created)

      rt = RouletteText.order(:created_at).last
      expect(rt.user_id).to eq current_user.id
      expect(rt.text).to eq 'Strong param test'
      # Extra attributes should not have been mass-assigned; created_at remains after save but user_id override tested.
      expect(rt.created_at).to be > 1.minute.ago
    end
  end
end 