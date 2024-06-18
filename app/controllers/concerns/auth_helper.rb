module AuthHelper
  def authenticate_user
    token = fetch_token
    Rails.logger.debug "JWT token: #{token.inspect}"

    if token
      user_payload = decode_token(token)
      Rails.logger.debug "User payload: #{user_payload.inspect}"

      if user_payload.nil?
        render_unauthorized('Unauthorized1')
        return
      end

      find_current_user(user_payload)
    else
      render_unauthorized('Unauthorized')
    end
  end

  def fetch_token
    cookies.signed[:jwt] || request.headers['Authorization']&.split(' ')&.last
  end

  def find_current_user(user_payload)
    user_id = user_payload['user_id']
    if user_id
      @current_user = User.find_by(id: user_id)
      Rails.logger.debug "Found user: #{@current_user.inspect}"
    else
      Rails.logger.debug "Failed to extract user_id from payload"
      render_unauthorized('Unauthorized2')
    end
  end

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end

  def decode_token(token)
    decoded_token = JWT.decode(token, Rails.application.secrets.secret_key_base, true, algorithm: 'HS256').first
    Rails.logger.debug "Decoded token: #{decoded_token}"
    decoded_token
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT DecodeError: #{e.message}"
    nil
  end
end
