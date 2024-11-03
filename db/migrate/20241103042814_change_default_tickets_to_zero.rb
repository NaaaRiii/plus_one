class ChangeDefaultTicketsToZero < ActiveRecord::Migration[7.0]
  def change
    change_column_default :users, :play_tickets, from: 5, to: 0
    change_column_default :users, :edit_tickets, from: 5, to: 0
  end
end
