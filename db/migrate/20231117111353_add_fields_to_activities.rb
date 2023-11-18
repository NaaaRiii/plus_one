class AddFieldsToActivities < ActiveRecord::Migration[7.0]
  def change
    add_column :activities, :small_goal_id, :integer
    add_column :activities, :goal_id, :integer
    add_column :activities, :exp, :float
    add_column :activities, :completed_at, :datetime
  end
end
