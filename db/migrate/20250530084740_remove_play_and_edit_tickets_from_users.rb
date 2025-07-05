class RemovePlayAndEditTicketsFromUsers < ActiveRecord::Migration[7.0]
  def change
    remove_column :users, :play_tickets, :integer
    remove_column :users, :edit_tickets, :integer
  end
end
