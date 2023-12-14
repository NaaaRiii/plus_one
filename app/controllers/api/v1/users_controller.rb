module Api
  module V1
    class UsersController < ApplicationController
      def show
        user = User.find(params[:id])
        render json: { rank: user.calculate_rank, user_id: user.id }
      end
    end
  end
end