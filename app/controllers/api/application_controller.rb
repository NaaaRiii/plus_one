#module Api
#  class ApplicationController < ActionController::API
#    before_action :authenticate_user
#    include ActionController::Cookies

#    def current_user
#      authorization_header = request.headers['Authorization']
#      Rails.logger.debug "Authorization header: #{authorization_header.inspect}"

#      if authorization_header.present?
#        token = authorization_header.split(' ').last
#        Rails.logger.debug "JWT token: #{token.inspect}"

#        if JwtBlacklist.exists?(token: token)
#          Rails.logger.debug "Token has been revoked"
#          return nil
#        end

#        user_payload = decode_token(token)
#        Rails.logger.debug "User payload: #{user_payload.inspect}"

#        if user_payload
#          jti = user_payload['jti']
#          if jti && JwtBlacklist.exists?(jti: jti)
#            Rails.logger.debug "Token has been revoked"
#            return nil
#          end

#          user_id = user_payload['user_id']
#          @current_user = User.find_by(id: user_id)
#          Rails.logger.debug "Found user: #{@current_user.inspect}"
#        else
#          Rails.logger.debug "Invalid token payload"
#        end
#      else
#        Rails.logger.debug "Authorization header missing"
#      end
#      @current_user
#    end

#    # ユーザー認証を行うフィルター
#    def authenticate_user
#      unless current_user
#        render json: { error: 'Unauthorized' }, status: :unauthorized
#      end
#    end

#    private

#    def decode_token(token)
#      JWT.decode(token, Rails.application.secrets.secret_key_base, true, { algorithm: 'HS256' }).first
#    rescue JWT::DecodeError => e
#      Rails.logger.error "JWT DecodeError: #{e.message}"
#      nil
#    end
#  end
#end

require 'net/http'
require 'openssl'
require 'jwt'

module Api
  class ApplicationController < ActionController::API
    before_action :authenticate_user

    private

    # Cognito User Pool のリージョンとプールIDを環境変数から取得
    # 例: AWS_REGION=ap-northeast-1, COGNITO_USER_POOL_ID=ap-northeast-1_xxxxxxxx
    COGNITO_REGION = ENV['AWS_REGION']
    COGNITO_USER_POOL_ID = ENV['COGNITO_USER_POOL_ID']

    def authenticate_user
      token = extract_token_from_header
      unless token
        render json: { error: 'Unauthorized' }, status: :unauthorized
        return
      end

      begin
        # 1. Cognito の公開鍵(JWK)を取得
        user_payload = decode_cognito_jwt(token)

        # 2. Cognitoの "sub" or "custom:userid" などからユーザーを特定
        #    ここでは "sub" をそのまま user_id として扱う例
        cognito_sub = user_payload['sub']  # Cognitoが発行する一意なユーザーID
        # DBに cognito_sub を紐づけるカラムがあるなら find_by(sub: cognito_sub)
        @current_user = User.find_by(cognito_sub: cognito_sub)

        unless @current_user
          render json: { error: 'User not found' }, status: :unauthorized
          nil
        end
      rescue JWT::DecodeError => e
        Rails.logger.error "JWT DecodeError: #{e.message}"
        render json: { error: 'Invalid token' }, status: :unauthorized
      end
    end

    def extract_token_from_header
      auth_header = request.headers['Authorization']
      return nil unless auth_header.present?

      auth_header.split(' ').last  # "Bearer <token>" の <token> 部分を返す
    end

    def decode_cognito_jwt(token)
      # リージョン・ユーザープールIDをもとに JWKS エンドポイント生成
      jwks_url = "https://cognito-idp.#{COGNITO_REGION}.amazonaws.com/#{COGNITO_USER_POOL_ID}/.well-known/jwks.json"

      # 事前にCacheしておくか、毎回取得する
      jwks_response = Net::HTTP.get(URI(jwks_url))
      jwks_keys = JSON.parse(jwks_response)['keys']

      # JWT.decode のオプションで jwks を渡す
      payload, _header = JWT.decode(
        token,
        nil, # キーは nil (後で JWK で特定する)
        true, # 検証を有効
        {
          algorithms: ['RS256'],
          jwks: { keys: jwks_keys } # 取得した公開鍵を使う
        }
      )
      payload
    end
  end
end
