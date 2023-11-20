class ChangeExpToDecimalInSmallGoals < ActiveRecord::Migration[7.0]
  def change
    change_column :small_goals, :exp, :decimal, precision: 10, scale: 2
  end
end
