class DashboardsController < ApplicationController
  include UserAuthenticatable
  include DifficultyMultiplier
  authenticate_user_for_actions [:index]
  def index
    @current_user = current_user
    @activities = current_user.activities.order(created_at: :desc)
    @small_goals = current_user.small_goals.includes(:goal)
    @completed_small_goals = current_user.activities.where(completed: true)
    logger.debug "Completed activities: #{@completed_activities.inspect}"
    @total_exp = current_user.activities.sum(:exp)
    logger.debug "Total exp for user #{current_user.id}: #{@total_exp}"
    @calculate_rank = current_user.rank
  end

  def calculate_total_exp(user)
    user.tasks.sum(:exp) + user.small_goals.sum { |goal| goal.tasks.count * get_multiplier(goal.difficulty) }
  end

  private

  def calculate_exp_for_small_goal(small_goal)
    task_count = small_goal.tasks.count
    difficulty_multiplier = DIFFICULTY_MULTIPLIERS[small_goal.difficulty]
    exp = (task_count * difficulty_multiplier).round(1)
    logger.debug "Calculating exp for small goal: #{small_goal.id}"
    logger.debug "Task count: #{task_count}, Difficulty multiplier: #{difficulty_multiplier}, Calculated exp: #{exp}"
    exp
  end
end
