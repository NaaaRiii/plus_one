class CreateActivities < ActiveRecord::Migration[7.0]
  def change
    create_table :activities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :goal_title
      t.string :small_goal_title
      t.integer :exp_gained

      t.timestamps
    end
  end
end
