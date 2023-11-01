class AddDeadlineAndTaskToSmallGoals < ActiveRecord::Migration[7.0]
  def change
    add_column :small_goals, :deadline, :datetime
    add_column :small_goals, :task, :string
  end
end
