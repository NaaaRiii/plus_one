module Api
  class ActivitiesController < ApplicationController
    include AuthHelper
    
    before_action :authenticate_user

    def weekly_exp
      # 今日の日付を基準に5日前から明日までの範囲を取得
      today = Date.today
      start_date = today - 5.days
      end_date = today + 1.day
    
      # 該当範囲内の活動データを取得
      activities = Activity.where(completed_at: start_date..end_date)
      exp_by_day = activities.group_by_day(:completed_at, time_zone: 'Asia/Tokyo').sum(:exp_gained)
    
      # 5日前から明日までの日付範囲でexpデータを生成
      date_range = (start_date..end_date).map do |date|
        formatted_date = date.strftime("%a, %b %d")
        { date: formatted_date, exp: exp_by_day[date] || 0 }
      end
    
      # フロントエンドにデータを送信

      render json: date_range
    end

    

    #def daily_exp
    #  start_of_month = Date.today.beginning_of_month
    #  end_of_month = Date.today.end_of_month

    #  activities = current_user.activities.where(completed_at: start_of_month..end_of_month)
    #  exp_by_day = activities.group_by_day(:completed_at, time_zone: 'Asia/Tokyo').sum(:exp_gained)

    #  formatted_exp_by_day = {}
    #  (start_of_month..end_of_month).each do |date|
    #    formatted_date = date.strftime("%Y-%m-%d")
    #    formatted_exp_by_day[formatted_date] = exp_by_day[date] || 0
    #  end

    #  exp_by_day.each do |key, value|
    #    formatted_key = key.is_a?(Date) ? key.strftime("%Y-%m-%d") : key
    #    formatted_exp_by_day[formatted_key] ||= value
    #  end

    #  sorted_exp_by_day = formatted_exp_by_day.sort_by { |key, _value| key }.to_h

    #  render json: sorted_exp_by_day
    #end
    
    def daily_exp
      start_of_month = Date.today.beginning_of_month
      end_of_month = Date.today.end_of_month.end_of_day
    
      activities = current_user.activities.where(completed_at: start_of_month..end_of_month)
      exp_by_day = activities.group_by_day(:completed_at, time_zone: 'Asia/Tokyo').sum(:exp_gained)
    
      # デバッグ情報を追加
      puts "Start of month: #{start_of_month}"
      puts "End of month: #{end_of_month}"
      puts "Activities: #{activities.inspect}"
      puts "Exp by day: #{exp_by_day.inspect}"
    
      formatted_exp_by_day = {}
      (start_of_month..end_of_month).each do |date|
        formatted_date = date.strftime("%Y-%m-%d")
        formatted_exp_by_day[formatted_date] = exp_by_day[date] || 0
      end
    
      exp_by_day.each do |key, value|
        formatted_key = key.is_a?(Date) ? key.strftime("%Y-%m-%d") : key
        formatted_exp_by_day[formatted_key] ||= value
      end
    
      sorted_exp_by_day = formatted_exp_by_day.sort_by { |key, _value| key }.to_h
    
      render json: sorted_exp_by_day
    end
  end
end
