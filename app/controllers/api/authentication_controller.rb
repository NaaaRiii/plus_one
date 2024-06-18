module Api
  class AuthenticationController < ApplicationController
    skip_before_action :authenticate_user, only: [:login]

    def login
      Rails.logger.debug "Login request received with params: #{params.inspect}"

      user = User.find_by(email: params[:email])
      Rails.logger.debug "User found: #{user.inspect}"

      if user&.authenticate(params[:password])
        token = encode_token({ user_id: user.id })

        cookies.signed[:jwt] = {
          value: token,
          httponly: true,
          secure: Rails.env.production?
        }

        render json: { message: 'Logged in successfully' }, status: :ok
      else
        render json: { error: 'Invalid email or password' }, status: :unauthorized
      end
    end

    private

    def encode_token(payload)
      JWT.encode(payload, Rails.application.secrets.secret_key_base)
    end
  end
end