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
    end
  end
end
