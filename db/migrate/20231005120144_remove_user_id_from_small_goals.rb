class RemoveUserIdFromSmallGoals < ActiveRecord::Migration[7.0]
  def change
    remove_column :small_goals, :user_id, :integer
  end
end
