module Api
  class UsersController < ApplicationController
    before_action :find_current_user
    before_action :authenticate_user

    def show
      if @current_user
        latest_completed_goals = @current_user.small_goals
                                              .where(completed: true)
                                              .where('completed_time > ?', 24.hours.ago)
                                              .order(completed_time: :desc)
                                              .limit(5)
  
        # レスポンスデータの構造を作成
        response_data = {
          name: @current_user.name,
          totalExp: @current_user.total_exp,
          rank: @current_user.calculate_rank,
          tickets: @current_user.tickets,
          #currentTitle: @current_user.current_title,
          latestCompletedGoals: latest_completed_goals.as_json(only: [:id, :title, :completed_time])
        }
  
        render json: response_data
      else
        render json: { error: "User not found" }, status: :not_found
      end
    end

    private

    def find_current_user
      @current_user = User.find_by(id: params[:id])
    end
  end
end
