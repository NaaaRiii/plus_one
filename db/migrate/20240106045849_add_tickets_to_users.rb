class AddTicketsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :tickets, :integer
  end
end
