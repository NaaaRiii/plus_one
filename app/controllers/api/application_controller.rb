require 'net/http'
require 'openssl'
require 'jwt'

module Api
  class ApplicationController < ActionController::API
    before_action :authenticate_user, except: [:health]

    private

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
      issuer    = "https://cognito-idp.#{COGNITO_REGION}.amazonaws.com/#{COGNITO_USER_POOL_ID}"
      jwks_keys = Rails.cache.fetch('cognito_jwks', expires_in: 12.hours) do
                    uri  = URI("#{issuer}/.well-known/jwks.json")
                    http = Net::HTTP.new(uri.host, 443).tap { |h| h.use_ssl = true }
                    JSON.parse(http.get(uri.request_uri).body)['keys']
                  end
    
      unverified_header = JWT.decode(token, nil, false).last
      jwk               = jwks_keys.find { |k| k['kid'] == unverified_header['kid'] }
    
      raise JWT::VerificationError, 'Unknown kid' unless jwk
    
      JWT.decode(
        token,
        OpenSSL::X509::Certificate.new(
          JWT::JWK.import(jwk).public_key.to_pem
        ).public_key,
        true,
        {
          algorithms: ['RS256'],
          iss: issuer,
          verify_iss: true,
          aud: ENV['COGNITO_APP_CLIENT_ID'],
          verify_aud: true
        }
      ).first
    end    
  end
end
