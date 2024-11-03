class EditTicketsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :play_tickets, :integer, default: 0
    add_column :users, :edit_tickets, :integer, default: 0
  end
end
