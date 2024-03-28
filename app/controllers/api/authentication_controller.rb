module Api
  class AuthenticationController < ApplicationController
    skip_before_action :verify_authenticity_token

    def login
      user = User.find_by(email: params[:email])
      if user&.authenticate(params[:password])
        token = user.generate_auth_token
        render json: { token: token }, status: :ok
      else
        render json: { error: 'Invalid email or password' }, status: :unauthorized
      end
    end
  end
end