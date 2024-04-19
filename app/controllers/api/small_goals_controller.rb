module Api
  class SmallGoalsController < ApplicationController
    before_action :authenticate_user
    before_action :set_goal, only: [:index, :create]

    def index
      @small_goals = @goal.small_goals.includes(:tasks)
      render json: @small_goals.as_json(include: :tasks)
    end

    def create
      @small_goal = @goal.small_goals.build(small_goal_params)
      if @small_goal.save
        render json: @small_goal.as_json(include: :tasks), status: :created
      else
        render json: @small_goal.errors, status: :unprocessable_entity
      end
    end

    private

    def set_goal
      @goal = current_user.goals.find(params[:goal_id])
    end

    def small_goal_params
      params.require(:small_goal).permit(:title, :difficulty, :deadline, :completed, :completed_time, tasks_attributes: [:content, :completed, :_destroy])
    end
  end
end
