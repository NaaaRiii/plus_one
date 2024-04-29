module Api
  class CurrentUsersController < ApplicationController
    before_action :authenticate_user

    def show
      if @current_user
        # 24時間以内に完了した small_goals を取得
        latest_completed_goals_within_24h = @current_user.small_goals
                                              .where(completed: true)
                                              .where('completed_time > ?', 24.hours.ago)
                                              .order(completed_time: :desc)
                                              .limit(5)

        # 24時間以内に完了したものがなければ、最新の完了したものを取得
        if latest_completed_goals_within_24h.empty?
          latest_completed_goal = @current_user.small_goals
                                    .where(completed: true)
                                    .order(completed_time: :desc)
                                    .first
          # 最新の完了したものが存在する場合、その1つだけを含む配列を作成
          latest_completed_goals = latest_completed_goal.present? ? [latest_completed_goal] : []
        else
          latest_completed_goals = latest_completed_goals_within_24h
        end
      
        # 他のユーザーデータとともにlatest_completed_goalsをレスポンスに含める
        response_data = {
          id: @current_user.id,
          name: @current_user.name,
          email: @current_user.email,
          totalExp: @current_user.total_exp,
          rank: @current_user.calculate_rank,
          last_roulette_rank: @current_user.last_roulette_rank,
          goals: @current_user.goals.as_json(include: :small_goals),
          tasks: @current_user.tasks,
          rouletteTexts: @current_user.roulette_texts,
          tickets: @current_user.tickets,
          latestCompletedGoals: latest_completed_goals.as_json(only: [:id, :title, :completed_time])
        }
    
        render json: response_data
      else
        render json: { error: "User not found" }, status: :not_found
      end
    end

    def authenticate_user
      authorization_header = request.headers['Authorization']
      if authorization_header.present?
        token = authorization_header.split(' ').last
        user_payload = decode_token(token) # decoded_token.first の呼び出しを削除しました。
        Rails.logger.info "User payload: #{user_payload.inspect}"
    
        if user_payload.nil?
          render json: { error: 'Unauthorized1' }, status: :unauthorized
          return
        end
    
        user_id = user_payload['user_id']
        if user_id
          @current_user = User.find_by(id: user_id)
          Rails.logger.info "Found user: #{@current_user.inspect}"
        else
          Rails.logger.info "Failed to extract user_id from payload"
          render json: { error: 'Unauthorized2' }, status: :unauthorized
          return
        end
    
        # 認証成功時の処理をここに記述
      end
    end

    def update_rank
      new_rank = params[:new_rank].to_i
      if @current_user.update(last_roulette_rank: new_rank)
        render json: { success: true, message: 'Rank updated successfully.' }
      else
        render json: { success: false, message: 'Failed to update rank.' }, status: :unprocessable_entity
      end
    end
    
    private
    
    require 'jwt'
    
    def decode_token(token)
      begin
        decoded_token = JWT.decode(token, Rails.application.secrets.secret_key_base, true, algorithm: 'HS256').first
        Rails.logger.info "Decoded token: #{decoded_token}"
        return decoded_token # ここでペイロード（ハッシュ）をそのまま返します。
      rescue JWT::DecodeError => e
        Rails.logger.error "JWT DecodeError: #{e.message}"
        nil
      end
    end
    
  end
end
