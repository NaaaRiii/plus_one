class ChangeTotalExpScale < ActiveRecord::Migration[7.0]
  def change
    change_column :users, :total_exp, :decimal, precision: 10, scale: 2
  end
end
