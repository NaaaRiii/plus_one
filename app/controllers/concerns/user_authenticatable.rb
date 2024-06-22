module UserAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user
  end

  class_methods do
    def authenticate_user_for_actions(actions = [])
      before_action :logged_in_user, only: actions
    end
  end

  private

  def logged_in_user
    return if logged_in?

    store_location
    render json: { error: "Please log in." }, status: :unauthorized
  end

  def authenticate_user
    authorization_header = request.headers['Authorization']
    return unless authorization_header.present?

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
      nil
    end

    
  end

  # トークンによってユーザーが正しいかどうかを確認
  def correct_user
    @user = User.find(params[:id])
    render json: { error: "Not authorized." }, status: :forbidden unless @current_user == @user
  end

  require 'jwt'
  
  def decode_token(token)
    
    decoded_token = JWT.decode(token, Rails.application.secrets.secret_key_base, true, algorithm: 'HS256').first
    Rails.logger.info "Decoded token: #{decoded_token}"
    decoded_token # ここでペイロード（ハッシュ）をそのまま返します。
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT DecodeError: #{e.message}"
    nil
    
  end
    
end

  