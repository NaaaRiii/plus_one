class AddDifficultyColumnToSmallGoals < ActiveRecord::Migration[7.0]
  def change
    add_column :small_goals, :difficulty, :string
  end
end
