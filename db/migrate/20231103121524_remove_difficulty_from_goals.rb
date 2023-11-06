class RemoveDifficultyFromGoals < ActiveRecord::Migration[7.0]
  def change
    remove_column :goals, :difficulty, :string
  end
end
