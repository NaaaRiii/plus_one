class RemoveUnusedColumns < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :current_goal_id
    remove_column :goals, :current_small_goal_id
    remove_column :small_goals, :current_task_id
  end
end
