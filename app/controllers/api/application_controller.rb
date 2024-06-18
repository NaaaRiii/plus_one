#module Api
#  class ApplicationController < ActionController::API
#    include UserAuthenticatable
#    def current_user
#      @current_user ||= User.find_by(auth_token: request.headers['Authorization'])
#    end
#  end
#end

#module Api
#  class ApplicationController < ActionController::API
#    # JWTトークンをデコードしてユーザーを特定する
#    def current_user
#      header = request.headers['Authorization']
#      header = header.split(' ').last if header
#      if header
#        begin
#          decoded = JWT.decode(header, Rails.application.secrets.secret_key_base, true, { algorithm: 'HS256' }).first
#          @current_user ||= User.find(decoded['user_id'])
#        rescue JWT::DecodeError
#          nil
#        end
#      end
#    end

#    # ユーザー認証を行うフィルター
#    def authenticate_user
#      unless current_user
#        render json: { error: 'Unauthorized' }, status: :unauthorized
#      end
#    end
#  end
#end

module Api
  class ApplicationController < ActionController::API
    before_action :authenticate_user
    include ActionController::Cookies

    # 現在のユーザーを取得する
    #def current_user
    #  @current_user ||= authenticate_token
    #end
    #def current_user
    #  return @current_user if @current_user

    #  token = cookies.signed[:jwt]
    #  return unless token

    #  begin
    #    decoded = JWT.decode(token, Rails.application.secrets.secret_key_base, true, { algorithm: 'HS256' }).first
    #    @current_user = User.find(decoded['user_id'])
    #  rescue JWT::DecodeError
    #    nil
    #  end
    #end
    def current_user
      authorization_header = request.headers['Authorization']
      Rails.logger.debug "Authorization header: #{authorization_header.inspect}"

      if authorization_header.present?
        token = authorization_header.split(' ').last
        Rails.logger.debug "JWT token: #{token.inspect}"

        user_payload = decode_token(token)
        Rails.logger.debug "User payload: #{user_payload.inspect}"

        if user_payload
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

    # JWTトークンをデコードしてユーザーを特定する
    #def authenticate_token
    #  token = cookies.signed[:jwt]
    #  if token
    #    begin
    #      decoded = JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: 'HS256' }).first
    #      User.find(decoded['user_id'])
    #    rescue JWT::DecodeError
    #      nil
    #    end
    #  end
    #end
  end
end