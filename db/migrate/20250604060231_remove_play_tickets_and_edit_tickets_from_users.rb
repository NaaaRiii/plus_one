class RemovePlayTicketsAndEditTicketsFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :play_tickets, :integer if column_exists?(:users, :play_tickets)
    remove_column :users, :edit_tickets, :integer if column_exists?(:users, :edit_tickets)
  end
end
