class AddGoalIdToSmallGoals < ActiveRecord::Migration[7.0]
  def change
    add_column :small_goals, :goal_id, :integer
  end
end
