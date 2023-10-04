class RemoveGoalIdFromTasks < ActiveRecord::Migration[7.0]
  def change
    remove_reference :tasks, :goal, index: true, foreign_key: true
  end
end
