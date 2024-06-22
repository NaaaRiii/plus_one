module Api
  class ApplicationController < ActionController::API
    before_action :authenticate_user
    include ActionController::Cookies

    def current_user
      authorization_header = request.headers['Authorization']
      Rails.logger.debug "Authorization header: #{authorization_header.inspect}"

      if authorization_header.present?
        token = authorization_header.split(' ').last
        Rails.logger.debug "JWT token: #{token.inspect}"

        if JwtBlacklist.exists?(token: token)
          Rails.logger.debug "Token has been revoked"
          return nil
        end

        user_payload = decode_token(token)
        Rails.logger.debug "User payload: #{user_payload.inspect}"

        if user_payload
          jti = user_payload['jti']
          if jti && JwtBlacklist.exists?(jti: jti)
            Rails.logger.debug "Token has been revoked"
            return nil
          end

          user_id = user_payload['user_id']
          @current_user = User.find_by(id: user_id)
          Rails.logger.debug "Found user: #{@current_user.inspect}"
        else
          Rails.logger.debug "Invalid token payload"
        end
      else
        Rails.logger.debug "Authorization header missing"
      end
      @current_user
    end

    # ユーザー認証を行うフィルター
    def authenticate_user
      unless current_user
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end

    private

    def decode_token(token)
      JWT.decode(token, Rails.application.secrets.secret_key_base, true, { algorithm: 'HS256' }).first
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT DecodeError: #{e.message}"
      nil
    end
  end
end