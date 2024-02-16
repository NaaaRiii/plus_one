class ActivitiesController < ApplicationController
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
end
