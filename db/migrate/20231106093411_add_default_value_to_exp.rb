class AddDefaultValueToExp < ActiveRecord::Migration[7.0]
  def up
    change_column :users, :exp, :integer, default: 0
    # 既存のユーザーで exp が nil のものを 0 に設定
    User.where(exp: nil).update_all(exp: 0)
  end

  def down
    change_column :users, :exp, :integer, default: nil
  end
end
