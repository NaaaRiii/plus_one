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

  describe 'GET #daily_exp' do
    context '認証済みユーザーの場合' do
      let(:three_months_ago) { 3.months.ago.beginning_of_month.to_date }
      let(:end_of_month) { [Date.current, Date.current.end_of_month.to_date].min }

      before do
        # 3ヶ月前のデータ
        create(:activity,
               user: user,
               completed_at: Time.zone.local(three_months_ago.year, three_months_ago.month, three_months_ago.day, 12),
               exp_gained: 100,
               goal: create(:goal, user: user))

        # 2ヶ月前のデータ
        create(:activity,
               user: user,
               completed_at: Time.zone.local((three_months_ago + 1.month).year,
                                             (three_months_ago + 1.month).month,
                                             15, # 15日に設定
                                             12),
               exp_gained: 200,
               goal: create(:goal, user: user))

        # 今月のデータ
        create(:activity,
               user: user,
               completed_at: Time.zone.local(Date.current.year,
                                             Date.current.month,
                                             Date.current.day,
                                             12),
               exp_gained: 300,
               goal: create(:goal, user: user))
      end

      it '3ヶ月前から今月末までの期間のデータが返されること' do
        get :daily_exp
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)

        # 日付範囲の確認
        dates = json_response.keys.map { |date_str| Date.parse(date_str) }
        expect(dates.min).to eq(three_months_ago)
        expect(dates.max).to eq(end_of_month)

        # 特定の日付のexpを確認
        expect(json_response[three_months_ago.strftime('%Y-%m-%d')]).to eq(100)
        expect(json_response[(three_months_ago + 1.month + 14.days).strftime('%Y-%m-%d')]).to eq(200)
        expect(json_response[Date.current.strftime('%Y-%m-%d')]).to eq(300)
      end

      it '日付フォーマットが正しいこと ("YYYY-MM-DD" 形式)' do
        get :daily_exp
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        date_regex = /\A\d{4}-\d{2}-\d{2}\z/
        json_response.keys.each do |date|
          expect(date).to match(date_regex)
        end
      end

      it '活動がない日のexpが0として返されること' do
        get :daily_exp
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        # 複数の日付で0のチェック
        no_activity_date = (three_months_ago + 1.day).strftime('%Y-%m-%d')
        middle_date = (three_months_ago + 1.month + 5.days).strftime('%Y-%m-%d')
        recent_date = (Date.current - 1.day).strftime('%Y-%m-%d')

        expect(json_response[no_activity_date]).to eq(0)
        expect(json_response[middle_date]).to eq(0)
        expect(json_response[recent_date]).to eq(0)

        # 0の日付が期間内のすべての日に存在することを確認
        date_range = (three_months_ago..end_of_month).map { |date| date.strftime('%Y-%m-%d') }
        zero_dates = json_response.select { |_date, exp| exp == 0 }.keys
        expect(zero_dates).to include(*date_range - [
          three_months_ago.strftime('%Y-%m-%d'),
          (three_months_ago + 1.month + 14.days).strftime('%Y-%m-%d'),
          Date.current.strftime('%Y-%m-%d')
        ])
      end

      it '同じ日の活動のexpが正しく合計されること' do
        # 3ヶ月前の日付に複数の活動を追加
        create(:activity,
               user: user,
               completed_at: Time.zone.local(three_months_ago.year,
                                             three_months_ago.month,
                                             three_months_ago.day,
                                             14), # 14:00に設定
               exp_gained: 50,
               goal: create(:goal, user: user))

        # 今日の日付に追加の活動を作成
        create(:activity,
               user: user,
               completed_at: Time.zone.local(Date.current.year,
                                             Date.current.month,
                                             Date.current.day,
                                             15), # 15:00に設定
               exp_gained: 150,
               goal: create(:goal, user: user))

        get :daily_exp
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        three_months_ago_exp = json_response[three_months_ago.strftime('%Y-%m-%d')]
        today_exp = json_response[Date.current.strftime('%Y-%m-%d')]

        # 3ヶ月前の活動の合計 (100 + 50 = 150)
        expect(three_months_ago_exp).to eq(150)
        # 今日の活動の合計 (300 + 150 = 450)
        expect(today_exp).to eq(450)
      end

      it '日付でソートされていること' do
        get :daily_exp
        expect(response).to have_http_status(:ok)

        json_response = JSON.parse(response.body)
        dates = json_response.keys

        # 日付が昇順にソートされていることを確認
        expect(dates).to eq(dates.sort)

        # 最初と最後の日付が正しいことを確認
        expect(Date.parse(dates.first)).to eq(three_months_ago)
        expect(Date.parse(dates.last)).to eq(end_of_month)

        # 日付が連続していることを確認
        dates.each_cons(2) do |date1, date2|
          expect(Date.parse(date2) - Date.parse(date1)).to eq(1)
        end
      end
    end

    context '未認証ユーザーの場合' do
      before do
        # 認証モックを解除
        allow(controller).to receive(:authenticate_user).and_call_original
        allow(controller).to receive(:current_user).and_return(nil)
        request.headers['Authorization'] = nil
      end

      it '401 Unauthorizedが返されること' do
        get :daily_exp
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Unauthorized')
      end
    end
  end

  describe 'OPTIONS request' do
    before do
      # 認証モックを解除（デフォルトの動作に戻す）
      allow(controller).to receive(:authenticate_user).and_call_original
      # 認証ヘッダーを削除
      request.headers['Authorization'] = nil
    end

    it '認証チェックがスキップされること' do
      # daily_expアクションに対するOPTIONSリクエスト
      process :daily_exp, method: :options
      expect(response).to have_http_status(:ok)

      # weekly_expアクションに対するOPTIONSリクエスト
      process :weekly_exp, method: :options
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'エラーハンドリング' do
    context 'データベースエラーが発生した場合' do
      before do
        allow_any_instance_of(ActiveRecord::Relation).to receive(:where).and_raise(ActiveRecord::StatementInvalid.new("Database error"))
      end

      it 'weekly_expアクションでエラーが発生すること' do
        expect do
          get :weekly_exp
        end.to raise_error(ActiveRecord::StatementInvalid, "Database error")
      end

      it 'daily_expアクションでエラーが発生すること' do
        expect do
          get :daily_exp
        end.to raise_error(ActiveRecord::StatementInvalid, "Database error")
      end
    end

    context '不正なパラメータが指定された場合' do
      before do
        # 不正な日付範囲を強制的に設定
        allow(Date).to receive(:today).and_return(Date.new(2025, 1, 1))
        allow_any_instance_of(Date).to receive(:end_of_month).and_return(Date.new(2024, 12, 31))
      end

      it 'daily_expアクションで正常に処理されること' do
        get :daily_exp
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response).to be_empty
      end
    end
  end
end
