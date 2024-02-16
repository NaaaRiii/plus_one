class ChangeExpGainedToDecimalInActivities < ActiveRecord::Migration[7.0]
  def change
    change_column :activities, :exp_gained, :decimal, precision: 10, scale: 2, default: 0.0
  end
end
