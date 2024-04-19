module Api
  class GoalsController < ApplicationController
    before_action :authenticate_user
    before_action :set_goal, only: [:show, :update, :destroy]

    def index
      @goals = current_user.goals.includes(:small_goals)
      render json: @goals.as_json(include: [:small_goals])
    end

    def show
      if @goal
        render json: @goal.as_json(include: [:small_goals])
      else
        render json: { error: "Goal not found" }, status: :not_found
      end
    end

    def create
      @goal = current_user.goals.build(goal_params)
      if @goal.save
        render json: { id: @goal.id, message: "Goal is saved. Next, let's create a small goal. This is a small goal to achieve your goal." }, status: :created
      else
        render json: @goal.errors, status: :unprocessable_entity
      end
    end

    def update
      if @goal.update(goal_params)
        render json: @goal, status: :ok
      else
        render json: @goal.errors, status: :unprocessable_entity
      end
    end

    def destroy
      @goal = current_user.goals.find(params[:id])
      if @goal.destroy
        render json: { message: 'Goal was successfully deleted.' }, status: :ok
      else
        render json: @goal.errors, status: :unprocessable_entity
      end
    end

    private

    def set_goal
      @goal = current_user.goals.find_by(id: params[:id])
    end

    def goal_params
      params.require(:goal).permit(:title, :content, :deadline, small_goals_attributes: [:title, :content, :deadline])
    end
  end
end
