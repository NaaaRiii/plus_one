class AddCompletedTimeToSmallGoals < ActiveRecord::Migration[7.0]
  def change
    add_column :small_goals, :completed_time, :datetime, default: nil
  end
end
