#module Api
#  class ApplicationController < ActionController::API
#    include UserAuthenticatable
#    def current_user
#      @current_user ||= User.find_by(auth_token: request.headers['Authorization'])
#    end
#  end
#end

module Api
  class ApplicationController < ActionController::API
    # JWTトークンをデコードしてユーザーを特定する
    def current_user
      header = request.headers['Authorization']
      header = header.split(' ').last if header
      if header
        begin
          decoded = JWT.decode(header, Rails.application.secrets.secret_key_base, true, { algorithm: 'HS256' }).first
          @current_user ||= User.find(decoded['user_id'])
        rescue JWT::DecodeError
          nil
        end
      end
    end

    # ユーザー認証を行うフィルター
    def authenticate_user
      unless current_user
        render json: { error: 'Unauthorized' }, status: :unauthorized
      end
    end
  end
end