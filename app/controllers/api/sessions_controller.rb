module Api
  class SessionsController < ApplicationController
    before_action :authenticate_user

    def destroy
      current_user.invalidate_token
      head :no_content
      render json: { message: 'Logged out successfully' }, status: :ok
    end
  end
end