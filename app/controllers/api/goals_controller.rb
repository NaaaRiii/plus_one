module Api
  class GoalsController < ApplicationController
    include DifficultyMultiplier
    before_action :authenticate_user
    before_action :set_goal, only: [:show, :update, :destroy, :complete]

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

    def complete
      @goal = Goal.find(params[:id])
  
      if @goal.small_goals.any? { |sg| !sg.completed }
        # すべての小目標が完了していない場合はエラーメッセージを返す
        render json: { success: false, message: "まだ完了していない小目標があります。" }, status: :unprocessable_entity
      else
        # すべての小目標が完了している場合
        @goal.update(completed: true)
        total_exp_gained = @goal.small_goals.sum(&:exp) * 3
        current_user.total_exp = (current_user.total_exp || 0) + total_exp_gained
        current_user.save
  
        Activity.create(
          user: current_user,
          goal: @goal,
          exp_gained: total_exp_gained,
          completed_at: Time.current
        )
  
        render json: { success: true, message: "Congratulations on completing your goal! EXP gained: #{total_exp_gained}" }, status: :ok
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

    #最終的に必要かは吟味が必要
    #def calculate_exp(goal)
    #  goal.small_goals.sum do |sg| 
    #    multiplier = DIFFICULTY_MULTIPLIERS[sg.difficulty] || 1.0
    #    sg.completed && sg.exp ? (sg.exp * multiplier) : 0
    #  end
    #end
  end
end
