class AddSmallGoalsIdToTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :tasks, :small_goal_id, :integer
  end
end
