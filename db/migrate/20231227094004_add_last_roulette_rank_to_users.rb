class AddLastRouletteRankToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :last_roulette_rank, :integer
  end
end
