class DashboardsController < ApplicationController
  include UserAuthenticatable
  authenticate_user_for_actions [:index]
  def index
    @activities = current_user.activities.order(created_at: :desc)
    @small_goals = current_user.small_goals.includes(:goal)
    @completed_small_goals = current_user.activities.where(completed: true)
    logger.debug "Completed activities: #{@completed_activities.inspect}"
  end
end
