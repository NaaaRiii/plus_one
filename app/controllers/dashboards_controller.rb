class DashboardsController < ApplicationController
  include UserAuthenticatable
  authenticate_user_for_actions [:index]
  def index
    @activities = current_user.activities.order(created_at: :desc)
    @small_goals = current_user.small_goals.includes(:goal)
    @completed_small_goals = current_user.activities.where(completed: true)
    logger.debug "Completed activities: #{@completed_activities.inspect}"
    @total_exp = current_user.small_goals.sum { |goal| calculate_exp_for_small_goal(goal) }
  end

  def calculate_total_exp(user)
    user.tasks.sum(:exp) + user.small_goals.sum { |goal| goal.tasks.count * difficulty_multiplier(goal.difficulty) }
  end

  private

  DIFFICULTY_MULTIPLIERS = {
    "ものすごく簡単" => 0.5,
    "簡単" => 0.7,
    "普通" => 1.0,
    "難しい" => 1.2,
    "とても難しい" => 1.5
  }.freeze

  def calculate_exp_for_small_goal(small_goal)
    task_count = small_goal.tasks.count
    difficulty_multiplier = DIFFICULTY_MULTIPLIERS[small_goal.difficulty]
    exp = (task_count * difficulty_multiplier).round(1)
    logger.debug "Calculating exp for small goal: #{small_goal.id}"
    logger.debug "Task count: #{task_count}, Difficulty multiplier: #{difficulty_multiplier}, Calculated exp: #{exp}"
    exp
  end
end
