module Api
  class SmallGoalsController < ApplicationController
    include DifficultyMultiplier
    include AuthHelper

    before_action :authenticate_user
    before_action :set_goal

    before_action :set_goal, only: [:index, :create, :complete]
    before_action :set_small_goal, only: [:show, :update, :complete, :destroy]

    def index
      @small_goals = @goal.small_goals.includes(:tasks)
      render json: @small_goals.as_json(include: :tasks)
    end

    def create
      @small_goal = @goal.small_goals.build(small_goal_params)

      if @small_goal.save
        render json: { message: "Goal is saved. Let's check it out." }, status: :created
      else
        render json: { errors: @small_goal.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def show
      render json: @small_goal.as_json(include: :tasks)
    end

    def update
      logger.debug "Received parameters: #{params.inspect}"
      if @small_goal.update(small_goal_params)
        params[:small_goal][:tasks_attributes]&.each do |task_params|
          if task_params[:_destroy].to_s == 'true'
            task = @small_goal.tasks.find_by(id: task_params[:id])
            task&.destroy
          end
        end
        render json: @small_goal, status: :ok
      else
        render json: @small_goal.errors, status: :unprocessable_entity
      end
    end

    def destroy
      if @small_goal.destroy
        render json: { status: 'success', message: 'Small goal was successfully deleted.' }, status: :ok
      else
        render json: { status: 'error', message: 'Failed to delete small goal.' }, status: :unprocessable_entity
      end
    end

    def complete
      if @small_goal.update(completed: true, completed_time: Time.current)
        exp_gained = calculate_exp_for_small_goal(@small_goal).round
        current_user.total_exp ||= 0
        current_user.total_exp += exp_gained
        current_user.save
  
        current_user.activities.create(
          goal_title: @small_goal.goal.title,
          small_goal_title: @small_goal.title,
          exp_gained: exp_gained,
          completed_at: Time.current
        )
  
        message = "#{@small_goal.title} completed successfully!"

        render json: { status: 'success', message: message, exp_gained: exp_gained }, status: :ok
      else
        render json: { status: 'error', message: 'There was a problem completing the small goal.' }, status: :unprocessable_entity
      end
    end

    private

    def set_goal
      @goal = current_user.goals.find(params[:goal_id])
    end

    def set_small_goal
      @small_goal = current_user.goals.find(params[:goal_id]).small_goals.find(params[:id])
    end

    def calculate_exp_for_small_goal(small_goal)
      task_count = small_goal.tasks.count
      difficulty_multiplier = DIFFICULTY_MULTIPLIERS[small_goal.difficulty] || 1.0
      exp = (task_count * difficulty_multiplier).round(1)
      logger.debug "Calculating exp for small goal: #{small_goal.id}"
      logger.debug "Task count: #{task_count}, Difficulty multiplier: #{difficulty_multiplier}, Calculated exp: #{exp}"
      exp
    end

    def small_goal_params
      params.require(:small_goal).permit(:title, :difficulty, :deadline, tasks_attributes: [:id, :content, :_destroy])
    end
  end
end
