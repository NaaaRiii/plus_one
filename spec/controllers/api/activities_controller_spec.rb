require 'rails_helper'

RSpec.describe Api::ActivitiesController, type: :controller do
  let(:user) { create(:user) }
  let(:token) { JWT.encode({ user_id: user.id, jti: SecureRandom.uuid }, Rails.application.secrets.secret_key_base, 'HS256') }

  before do
    # Cognito認証をモック
    allow(controller).to receive(:authenticate_user).and_return(true)
    allow(controller).to receive(:current_user).and_return(user)
  end

  def formatted(date)
    date.strftime("%a, %b %d")
  end

  describe 'GET #weekly_exp' do
    context '認証済みユーザーの場合' do
      let(:today) { Date.today }
      let(:start_date) { today - 5.days }
      let(:end_date) { today + 1.day }

      before do
        # 5日前のデータ
        create(:activity, :on_date,
               date: 5.days.ago.to_date,
               user: user,
               exp_gained: 300)

        # 3日前
        create(:activity, :on_date,
               date: 3.days.ago.to_date,
               user: user,
               exp_gained: 200)

        # 今日
        create(:activity, :on_date,
               date: Date.current,
               user: user,
               exp_gained: 100)

        # 明日 (日付境界を跨がないよう 0:00 で作成)
        create(:activity,
               user: user,
               completed_at: Time.zone.local(1.day.from_now.to_date.year, 1.day.from_now.to_date.month, 1.day.from_now.to_date.day, 0, 0, 0),
               exp_gained: 400,
               goal: create(:goal, user: user))
      end

      it '5日前から明日までの期間のデータが正しく返されること' do
        get :weekly_exp
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        
        # レスポンスの日数が正しいことを確認（5日前から明日までの7日分）
        expect(json_response.length).to eq(7)
        
        # 日付の範囲が正しいことを確認
        dates = json_response.map { |day| Date.parse(day['date']) }
        expect(dates.min).to eq(start_date)
        expect(dates.max).to eq(end_date)
        
        # 各日のexpが正しく合計されていることを確認
        today_exp = json_response.find { |day| day['date'] == formatted(today) }['exp']
        expect(today_exp).to eq(100)
        
        three_days_ago_exp = json_response.find { |day| day['date'] == formatted(today - 3.days) }['exp']
        expect(three_days_ago_exp).to eq(200)
        
        five_days_ago_exp = json_response.find { |day| day['date'] == formatted(start_date) }['exp']
        expect(five_days_ago_exp).to eq(300)
        
        tomorrow_exp = json_response.find { |day| day['date'] == formatted(end_date) }['exp']
        expect(tomorrow_exp).to eq(400)
      end

      it '日付フォーマットが正しいこと ("Mon, Jan 01" 形式)' do
        get :weekly_exp
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        date_regex = /\A[A-Z][a-z]{2}, [A-Z][a-z]{2,} \d{2}\z/
        json_response.each do |day|
          expect(day['date']).to match(date_regex)
        end
      end

      it '活動がない日のexpが0として返されること' do
        get :weekly_exp
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        # 2日前と4日前は活動データを作っていないので0になるはず
        two_days_ago = formatted(today - 2.days)
        four_days_ago = formatted(today - 4.days)

        two_days_ago_exp = json_response.find { |day| day['date'] == two_days_ago }['exp']
        four_days_ago_exp = json_response.find { |day| day['date'] == four_days_ago }['exp']

        expect(two_days_ago_exp).to eq(0)
        expect(four_days_ago_exp).to eq(0)
      end

      it '活動がある日のexpが正しく合計されること' do
        # 同じ日に複数の活動がある場合のテスト
        create(:activity,
               user: user,
               completed_at: Time.zone.local(today.year, today.month, today.day, 15, 0, 0), # 15:00に設定
               exp_gained: 150,
               goal: create(:goal, user: user))

        get :weekly_exp
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        today_exp = json_response.find { |day| day['date'] == formatted(today) }['exp']

        # 今日の活動の合計 (100 + 150 = 250)
        expect(today_exp).to eq(250)
      end
    end

    context '未認証ユーザーの場合' do
      before do
        # 認証モックを解除
        allow(controller).to receive(:authenticate_user).and_call_original
      end

      it '401 Unauthorizedが返されること' do
        get :weekly_exp
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
