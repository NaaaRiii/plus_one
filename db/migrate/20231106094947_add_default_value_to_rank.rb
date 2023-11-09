class AddDefaultValueToRank < ActiveRecord::Migration[7.0]
  def up
    change_column :users, :rank, :integer, default: 1
    # 既存のユーザーで rank が nil のものを 1 に設定
    User.where(rank: nil).update_all(rank: 1)
  end

  def down
    change_column :users, :rank, :integer, default: nil
  end
end
