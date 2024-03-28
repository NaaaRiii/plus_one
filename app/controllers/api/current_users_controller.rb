module Api
  class CurrentUsersController < ApplicationController
    before_action :authenticate_user

    def show
      if @current_user
        latest_completed_goals = @current_user.small_goals
                                  .where(completed: true)
                                  .where('completed_time > ?', 24.hours.ago)
                                  .order(completed_time: :desc)
                                  .limit(5)
  
        # レスポンスデータの構造を作成
        response_data = {
          id: @current_user.id,
          name: @current_user.name,
          email: @current_user.email,
          totalExp: @current_user.total_exp,
          rank: @current_user.calculate_rank,
          latestCompletedGoals: latest_completed_goals.as_json(only: [:id, :title, :completed_time])
        }
  
        # response_data を使用してレスポンスを返す
        render json: response_data
      else
        render json: { error: "User not found" }, status: :not_found
      end
    end

    #def authenticate_user
    #  authorization_header = request.headers['Authorization']
    #  if authorization_header.present?
    #    token = authorization_header.split(' ').last
    #    decoded_token = decode_token(token)
    #    Rails.logger.info "Decoded token: #{decoded_token.inspect}"
    
    #    if decoded_token.nil?
    #      render json: { error: 'Unauthorized1' }, status: :unauthorized
    #      return
    #    end
    
    #    user_payload = decoded_token.first
    #    Rails.logger.info "User payload: #{user_payload.inspect}"

    #    # user_id の正しい取得方法に修正
    #    user_id = user_payload.is_a?(Array) ? user_payload[1] : user_payload["user_id"]
    #    if user_id
    #      @current_user = User.find_by(id: user_id)
    #      Rails.logger.info "Found user: #{@current_user.inspect}"
    #    else
    #      Rails.logger.info "Failed to extract user_id from payload"
    #    end

    #    if @current_user.nil?
    #      render json: { error: 'Unauthorized2' }, status: :unauthorized
    #    else
    #      # 認証成功時の処理
    #    end
    #  end
    #end

    #def authenticate_user
    #  authorization_header = request.headers['Authorization']
    #  if authorization_header.present?
    #    token = authorization_header.split(' ').last
    #    decoded_token = decode_token(token)
    #    Rails.logger.info "Decoded token: #{decoded_token.inspect}"
        
    #    if decoded_token.nil?
    #      render json: { error: 'Unauthorized1' }, status: :unauthorized
    #      return
    #    end
    
    #    user_payload = decoded_token.first
    #    Rails.logger.info "User payload: #{user_payload.inspect}"
    
    #    #この部分だけでうまくいく
    #    user_id = user_payload['user_id']
    #    @current_user = User.find_by(id: user_id)
    #    #この部分だけでうまくいく

    #    # user_payloadがハッシュであることを確認し、キーと値をログに出力
    #    #if user_payload.is_a?(Hash)
    #    #  Rails.logger.info "user_payload is a Hash"
    #    #  user_payload.each do |key, value|
    #    #    Rails.logger.info "Key: #{key}, Value: #{value}"
    #    #  end
    
    #    #  user_id = user_payload['user_id']
    #    #  Rails.logger.info "Extracted user_id: #{user_id}"
    
    #    #  if user_id
    #    #    @current_user = User.find_by(id: user_id)
    #    #    Rails.logger.info "Found user: #{@current_user.inspect}"
    #    #  else
    #    #    Rails.logger.info "Failed to extract user_id from payload"
    #    #  end
    #    #else
    #    #  Rails.logger.info "user_payload is not a Hash"
    #    #end
    
    #    if @current_user.nil?
    #      render json: { error: 'Unauthorized2' }, status: :unauthorized
    #    else
    #      # 認証成功時の処理
    #    end
    #  end
    #end
    
    #private

    #require 'jwt'

    #def decode_token(token)
    #  begin
    #    #decoded_token = JWT.decode(token, Rails.application.secrets.secret_key_base, true, { algorithm: 'HS256' })
    #    decoded_token = JWT.decode(token, Rails.application.secrets.secret_key_base, true, { algorithm: 'HS256' }).first
    #    Rails.logger.info "Decoded token: #{decoded_token}"
    #    #payload = decoded_token.first
    #    user_payload = decoded_token
    #    #Rails.logger.info "Payload: #{payload.inspect}"
    #    Rails.logger.info "User payload: #{user_payload.inspect}"
        
    #    return user_payload
    #  rescue JWT::DecodeError => e
    #    Rails.logger.error "JWT DecodeError: #{e.message}"
    #    nil
    #  end
    #end

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
