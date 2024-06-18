class ChangeDecimalFieldsToInteger < ActiveRecord::Migration[7.0]
  def up
    change_column :users, :total_exp, :integer, using: 'total_exp::integer', default: 0
    change_column :small_goals, :exp, :integer, using: 'exp::integer'
    change_column :activities, :exp_gained, :integer, using: 'exp_gained::integer', default: 0
  end

  def down
    change_column :users, :total_exp, :decimal, precision: 10, scale: 2, default: "0.0"
    change_column :small_goals, :exp, :decimal, precision: 10, scale: 2
    change_column :activities, :exp_gained, :decimal, precision: 10, scale: 2, default: "0.0"
  end
end
