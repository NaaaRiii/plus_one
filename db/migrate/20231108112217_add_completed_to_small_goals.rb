class AddCompletedToSmallGoals < ActiveRecord::Migration[7.0]
  def change
    add_column :small_goals, :completed, :boolean, default: false
  end
end
