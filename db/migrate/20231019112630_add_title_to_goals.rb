class AddTitleToGoals < ActiveRecord::Migration[7.0]
  def change
    add_column :goals, :title, :string
    add_column :goals, :difficulty, :string
    add_column :goals, :deadline, :date
    add_column :goals, :small_goal, :string
  end
end
