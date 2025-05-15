#require 'net/http'
#require 'openssl'
#require 'jwt'

#module Api
#  class ApplicationController < ActionController::API
#    before_action :authenticate_user, except: [:health]

#    private

#    COGNITO_REGION = ENV['AWS_REGION']
#    COGNITO_USER_POOL_ID = ENV['COGNITO_USER_POOL_ID']

#    def authenticate_user
#      Rails.logger.info ">> Incoming Authorization: #{request.headers['Authorization'].inspect}"
#      token = extract_token_from_header
#      unless token
#        render json: { error: 'Unauthorized' }, status: :unauthorized
#        return
#      end

#      begin
#        # 1. Cognito の公開鍵(JWK)を取得
#        user_payload = decode_cognito_jwt(token)

#        # 2. Cognitoの "sub" or "custom:userid" などからユーザーを特定
#        #    ここでは "sub" をそのまま user_id として扱う例
#        cognito_sub = user_payload['sub']  # Cognitoが発行する一意なユーザーID
#        # DBに cognito_sub を紐づけるカラムがあるなら find_by(sub: cognito_sub)
#        @current_user = User.find_by(cognito_sub: cognito_sub)

#        unless @current_user
#          render json: { error: 'User not found' }, status: :unauthorized
#          nil
#        end
#      rescue JWT::DecodeError => e
#        Rails.logger.error "JWT DecodeError: #{e.message}"
#        render json: { error: 'Invalid token' }, status: :unauthorized
#      end
#    end

#    def extract_token_from_header
#      auth_header = request.headers['Authorization']
#      return nil unless auth_header.present?

#      auth_header.split(' ').last  # "Bearer <token>" の <token> 部分を返す
#    end

#    def decode_cognito_jwt(token)
#      issuer    = "https://cognito-idp.#{COGNITO_REGION}.amazonaws.com/#{COGNITO_USER_POOL_ID}"
#      jwks_keys = Rails.cache.fetch('cognito_jwks', expires_in: 12.hours) do
#                    uri  = URI("#{issuer}/.well-known/jwks.json")
#                    http = Net::HTTP.new(uri.host, 443).tap { |h| h.use_ssl = true }
#                    JSON.parse(http.get(uri.request_uri).body)['keys']
#                  end
    
#      unverified_header = JWT.decode(token, nil, false).last
#      jwk               = jwks_keys.find { |k| k['kid'] == unverified_header['kid'] }
    
#      raise JWT::VerificationError, 'Unknown kid' unless jwk
    
#      JWT.decode(
#        token,
#        OpenSSL::X509::Certificate.new(
#          JWT::JWK.import(jwk).public_key.to_pem
#        ).public_key,
#        true,
#        {
#          algorithms: ['RS256'],
#          iss: issuer,
#          verify_iss: true,
#          aud: ENV['COGNITO_APP_CLIENT_ID'],
#          verify_aud: true
#        }
#      ).first
#    end    
#  end
#end

module Api
  class ApplicationController < ActionController::API
    # トークン認証を必要としないエンドポイントを列挙
    #skip_before_action :authenticate_user, only: [:health]  

    before_action :authenticate_user, unless: -> { request.options? }

    private

    # 環境変数
    COGNITO_REGION         = ENV.fetch('AWS_REGION')
    COGNITO_USER_POOL_ID   = ENV.fetch('COGNITO_USER_POOL_ID')
    COGNITO_APP_CLIENT_ID  = ENV.fetch('COGNITO_APP_CLIENT_ID')

    # ユーザー認証
    def authenticate_user
      Rails.logger.info ">> Authorization: #{request.headers['Authorization']}"
      token = extract_token_from_header
      return render_unauthorized unless token

      begin
        payload = decode_cognito_jwt(token)

        return render_unauthorized unless payload['token_use'] == 'access'

        @current_user = User.find_by!(cognito_sub: payload['sub'])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'User not found' }, status: :unauthorized
      rescue JWT::ExpiredSignature
        render json: { error: 'Token has expired' }, status: :unauthorized
      rescue JWT::DecodeError, JWT::VerificationError => e
        Rails.logger.error "[JWT] #{e.class}: #{e.message}"
        render json: { error: 'Invalid token' }, status: :unauthorized
      end
    end

    def render_unauthorized
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end

    def extract_token_from_header
      header = request.headers['Authorization']
      return nil unless header&.start_with?('Bearer ')
      header.split(' ', 2).last
    end

    def decode_cognito_jwt(token)
      issuer = "https://cognito-idp.#{COGNITO_REGION}.amazonaws.com/#{COGNITO_USER_POOL_ID}"
      jwks   = Rails.cache.fetch('cognito_jwks', expires_in: 12.hours) do
        uri   = URI("#{issuer}/.well-known/jwks.json")
        JSON.parse(Net::HTTP.get(uri))['keys']
      end

      # ヘッダだけデコードして kid を抜く
      unverified_header = JWT.decode(token, nil, false).last
      jwk_data          = jwks.find { |k| k['kid'] == unverified_header['kid'] }
      raise JWT::VerificationError, 'Unknown kid' unless jwk_data

      # JWK → 公開鍵
      public_key = JWT::JWK.import(jwk_data).public_key

      # JWT の検証
      JWT.decode(
        token,
        public_key,
        true,
        {
          algorithm:    'RS256',
          iss:          issuer,
          verify_iss:   true,
          aud:          COGNITO_APP_CLIENT_ID,
          verify_aud:   true
        }
      ).first
    end

    # コントローラ／ビュー側で current_user を参照したいなら helper_method を宣言
    attr_reader :current_user
  end
end
