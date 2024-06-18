module Api
  class SessionsController < ApplicationController
    include AuthHelper

    def create
      user = User.find_by(email: params[:email])
      if user&.authenticate(params[:password])
        token = JWT.encode({ user_id: user.id }, Rails.application.secret_key_base)
        cookies.signed[:jwt] = { value: token, httponly: true, secure: Rails.env.production? }
        render json: { success: true }
      else
        render json: { success: false, error: 'Invalid email or password' }, status: :unauthorized
      end
    end
  
    def destroy
      cookies.delete(:jwt, httponly: true, secure: Rails.env.production?)
      render json: { success: true }
    end
  end
end