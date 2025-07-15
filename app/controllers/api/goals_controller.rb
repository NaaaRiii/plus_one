module Api
  class GoalsController < ApplicationController
    include DifficultyMultiplier

    before_action :authenticate_user, except: [:health], unless: -> { request.options? }
    before_action :set_goal, only: [:show, :update, :destroy, :complete]

    def index
      @goals = current_user.goals.includes(:small_goals)
      render json: @goals.as_json(include: [:small_goals], methods: [:completed_time])
    end

    def show
      #if (@goal = current_user.goals.includes(small_goals: :tasks).find(params[:id]))
      if @goal
        render json: @goal.to_json(include: { small_goals: { include: :tasks } }, methods: [:completed_time])
      else
        render json: { error: "Goal not found" }, status: :not_found
      end
    end

    def create
      unless current_user
        render json: { error: "ログインが必要です" }, status: :unauthorized
        return
      end

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
      #@goal = Goal.find(params[:id])
      unless @goal
        render json: { error: "Goal not found" }, status: :not_found
        return
      end
  
      if @goal.small_goals.any? { |sg| !sg.completed }
        # すべての小目標が完了していない場合はエラーメッセージを返す
        render json: { success: false, message: "まだ完了していない小目標があります。" }, status: :unprocessable_entity
      else
        # すべての小目標が完了している場合
        @goal.update(completed: true)
        total_exp_gained = @goal.small_goals.sum { |sg| sg.calculate_exp_for_small_goal * 3 }.round
        current_user.total_exp = (current_user.total_exp || 0) + total_exp_gained
        current_user.save

        new_rank  = current_user.calculate_rank
        Rails.logger.debug ">>> complete action: current_user.rank=#{new_rank}"
      
        current_user.update_tickets
      
        Rails.logger.debug "<<< after update_tickets: tickets=#{current_user.reload.tickets}"
        
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

    def small_goal_params
      params.require(:small_goal).permit(:title, :difficulty, :deadline, tasks_attributes: [:id, :content, :_destroy])
    end

  end
end
