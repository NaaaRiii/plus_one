class AddExpAndRankToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :exp, :integer
    add_column :users, :rank, :integer
  end
end
