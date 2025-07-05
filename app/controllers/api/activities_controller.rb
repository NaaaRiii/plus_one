module Api
  class ActivitiesController < ApplicationController
    #include AuthHelper
    
    before_action :authenticate_user, except: [:health], unless: -> { request.options? }

    def weekly_exp
      # 今日の日付を基準に5日前から明日までの範囲を取得
      today = Date.today
      start_date = today - 5.days
      end_date = today + 1.day
    
      # 該当範囲内の活動データを取得（current_userのactivitiesのみ）
      activities = current_user.activities.where(completed_at: start_date..end_date)
      exp_by_day = activities
                   .group_by_day(:completed_at, time_zone: 'Asia/Tokyo')
                   .sum(:exp_gained)
                   .transform_keys(&:to_date)
    
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
    #  end_of_month = Date.today.end_of_month.end_of_day
    
    #  activities = current_user.activities.where(completed_at: start_of_month..end_of_month)
    #  exp_by_day = activities.group_by_day(:completed_at, time_zone: 'Asia/Tokyo').sum(:exp_gained)
    
    #  # デバッグ情報を追加
    #  puts "Start of month: #{start_of_month}"
    #  puts "End of month: #{end_of_month}"
    #  puts "Activities: #{activities.inspect}"
    #  puts "Exp by day: #{exp_by_day.inspect}"
    
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
      start_of_month = 3.months.ago.beginning_of_month.to_date
      end_of_month = [Date.today, Date.today.end_of_month.to_date].min
    
      activities = current_user.activities.where(completed_at: start_of_month.beginning_of_day..end_of_month.end_of_day)
      exp_by_day = activities
                   .group_by_day(:completed_at, time_zone: 'Asia/Tokyo')
                   .sum(:exp_gained)
                   .transform_keys(&:to_date)
    
      # 以下はデバッグ用の出力です。本番環境では不要なため、コメントアウトしています。
      # puts "Start of month: #{start_of_month}"      # 3ヶ月前の月初めの日付
      # puts "End of month: #{end_of_month}"          # 今日の日付と今月末の日付の早い方
      # puts "Activities: #{activities.inspect}"       # 取得された活動データの詳細
      # puts "Exp by day: #{exp_by_day.inspect}"      # 日付ごとの経験値の合計
    
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
