class AddDefaultToTicketsInUsers < ActiveRecord::Migration[7.0]
  def change
    change_column_default :users, :tickets, from: nil, to: 0
  end
end
