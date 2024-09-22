class AddRankRestartOptionsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :restart_without_title, :boolean, default: false
    add_column :users, :legendary_hero_obtained_at, :datetime
  end
end
