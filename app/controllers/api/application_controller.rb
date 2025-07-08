require 'net/http'
require 'uri'

module Api
  class ApplicationController < ActionController::API

    private
  
    # 環境変数
    COGNITO_REGION         = ENV.fetch('AWS_REGION')
    COGNITO_USER_POOL_ID   = ENV.fetch('COGNITO_USER_POOL_ID')
    COGNITO_APP_CLIENT_ID  = ENV.fetch('COGNITO_APP_CLIENT_ID')

    # ユーザー認証
    def authenticate_user
      
      #token = request.headers['Authorization']&.split&.last

      #if Rails.env.development? && token == ENV['DUMMY_AUTH_TOKEN']
      #  @current_user = User.find_or_create_by!(email: 'dummy@example.com') do |u|
      #    u.name     = 'Dummy User'              # ← name を必ずセット
      #    u.password = SecureRandom.hex(8)        # 必要なら他の属性も
      #  end
      #  return
      #end

      Rails.logger.debug "[AUTH] called in #{self.class}##{action_name}"

      
      Rails.logger.debug ">> request.env[HTTP_AUTHORIZATION]: #{request.env['HTTP_AUTHORIZATION'].inspect}"

      raw = request.headers['Authorization'] || request.env['HTTP_AUTHORIZATION']
      unless raw&.start_with?('Bearer ')
        Rails.logger.debug ">> [Auth] Bearer token missing"
        return render_unauthorized
      end
      token = raw.split(' ', 2).last 

      begin
        payload = decode_cognito_jwt(token)
        Rails.logger.debug ">> [Auth] JWT payload: #{payload.inspect}"

        #@current_user = User.find_by!(cognito_sub: payload['sub'])
        @current_user = User.find_or_create_by!(cognito_sub: payload['sub']) do |u|
          u.email    = payload['email']
          u.name     = payload['name'] || 'Unknown User'
          u.password = SecureRandom.hex(16)
        end
      rescue ActiveRecord::RecordNotFound
        Rails.logger.debug ">> [Auth] Token expired"
        render json: { error: 'User not found' }, status: :unauthorized
      rescue JWT::ExpiredSignature
        Rails.logger.debug ">> [Auth] Token expired"
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
      raw = request.headers['Authorization'] || request.env['HTTP_AUTHORIZATION']
      return nil unless raw&.match?(/^Bearer\s+/i)

      token = raw.split(/\s+/, 2).last
      token.empty? ? nil : token
    end

    def decode_cognito_jwt(token)
      issuer = "https://cognito-idp.#{COGNITO_REGION}.amazonaws.com/#{COGNITO_USER_POOL_ID}"

      jwks = Rails.cache.fetch('cognito_jwks', expires_in: 12.hours) do
        uri = URI.parse("#{issuer}/.well-known/jwks.json")
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          http.get(uri.request_uri)
        end
        JSON.parse(response.body)['keys']
      end

      # ヘッダだけデコードして kid を抜く
      unverified_header = JWT.decode(token, nil, false).last
      jwk_data          = jwks.find { |k| k['kid'] == unverified_header['kid'] }
      raise JWT::VerificationError, 'Unknown kid' unless jwk_data

      public_key = JWT::JWK.import(jwk_data).public_key
      JWT.decode(
        token,
        public_key,
        true,
        {
          algorithm: 'RS256',
          iss: issuer,
          verify_iss: true,
          aud: COGNITO_APP_CLIENT_ID,
          verify_aud: true
        }
      ).first
    end

    # コントローラ／ビュー側で current_user を参照したいなら helper_method を宣言
    attr_reader :current_user
  end
end
