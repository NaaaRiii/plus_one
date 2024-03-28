class ActivitiesController < ApplicationController
  include UserAuthenticatable
  authenticate_user_for_actions [:daily_exp]

  def weekly_exp
    start_of_week = Date.today.beginning_of_week
    end_of_week = Date.today.end_of_week

    activities = Activity.where(completed_at: start_of_week..end_of_week)
    exp_by_day = activities.group_by_day(:completed_at, time_zone: 'Asia/Tokyo').sum(:exp_gained)

    # 現在の週の全日付を確保し、expがない場合は0を設定
    full_week_data = (start_of_week..end_of_week).map do |date|
      formatted_date = date.strftime("%a, %b %d")
      { date: formatted_date, exp: exp_by_day[date] || 0 }
    end

    render json: full_week_data
  end

  def daily_exp
    start_of_month = Date.today.beginning_of_month
    end_of_month = Date.today.end_of_month
  
    activities = current_user.activities.where(completed_at: start_of_month..end_of_month)
    exp_by_day = activities.group_by_day(:completed_at, time_zone: 'Asia/Tokyo').sum(:exp_gained)
  
    # 現在の月の全日についてのデータを保証し、キーを文字列に統一
    formatted_exp_by_day = {}
    (start_of_month..end_of_month).each do |date|
      formatted_date = date.strftime("%Y-%m-%d")
      formatted_exp_by_day[formatted_date] = exp_by_day[date] || 0
    end
  
    # 既存のデータがある場合、それも文字列キーのハッシュに追加
    exp_by_day.each do |key, value|
      formatted_key = key.is_a?(Date) ? key.strftime("%Y-%m-%d") : key
      formatted_exp_by_day[formatted_key] ||= value
    end
  
    # 文字列のキーを基準にしてソート
    sorted_exp_by_day = formatted_exp_by_day.sort_by { |key, _value| key }.to_h
  
    render json: sorted_exp_by_day
  end
  
  
end
