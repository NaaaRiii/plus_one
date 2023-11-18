class AddExpToSmallGoals < ActiveRecord::Migration[7.0]
  def change
    add_column :small_goals, :exp, :integer
  end
end
