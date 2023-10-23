class ModifySmallGoals < ActiveRecord::Migration[7.0]
  def change
    remove_column :small_goals, :difficulty, :string
    add_column :small_goals, :content, :text
  end
end
