module Api
  class ActivitiesController < ApplicationController
    
    before_action :authenticate_user, except: [:health], unless: -> { request.options? }

    def weekly_exp
      # 今日の日付を基準に5日前から明日までの範囲を取得
      today = Date.today
      start_date = today - 5.days
      end_date = today + 1.day

      # 該当範囲内の活動データを取得（current_userのactivitiesのみ）
      activities = current_user.activities.where(completed_at: start_date..end_date)
      exp_by_day = activities.group_by_day(:completed_at, time_zone: 'Asia/Tokyo').sum(:exp_gained)

      # 5日前から明日までの日付範囲でexpデータを生成
      date_range = (start_date..end_date).map do |date|
        formatted_date = date.strftime("%a, %b %d")
        { date: formatted_date, exp: exp_by_day[date] || 0 }
      end

      # フロントエンドにデータを送信

      render json: date_range
    end

    def daily_exp
      start_of_period, end_of_period = period_range_for_daily_exp

      activities = fetch_activities(start_of_period, end_of_period)
      exp_by_day  = aggregate_exp_by_date(activities)

      response_hash = build_daily_exp_response(start_of_period, end_of_period, exp_by_day)

      render json: response_hash
    end

    private

    # 3ヶ月前の月初〜今日または今月末の早い方
    def period_range_for_daily_exp
      start_date = 3.months.ago.beginning_of_month.to_date
      end_date   = [Date.today, Date.today.end_of_month.to_date].min
      [start_date, end_date]
    end

    # 指定期間の current_user の活動を取得
    def fetch_activities(start_date, end_date)
      current_user.activities.where(
        completed_at: start_date.beginning_of_day..end_date.end_of_day
      )
    end

    # Asia/Tokyo で日付毎に集計した Hash<Date => Integer>
    def aggregate_exp_by_date(activities)
      activities
        .group_by { |a| a.completed_at.in_time_zone('Asia/Tokyo').to_date }
        .transform_values { |acts| acts.sum(&:exp_gained) }
    end

    # レスポンス形式 "YYYY-MM-DD" => exp の連続 Hash に整形しソートして返す
    def build_daily_exp_response(start_date, end_date, exp_by_day)
      (start_date..end_date).each_with_object({}) do |date, hash|
        key = date.strftime('%Y-%m-%d')
        hash[key] = exp_by_day[date] || 0
      end.sort.to_h
    end
  end
end
