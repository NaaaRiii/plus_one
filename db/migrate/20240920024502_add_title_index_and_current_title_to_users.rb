class AddTitleIndexAndCurrentTitleToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :title_index, :integer, default: 0
    add_column :users, :current_title, :string
  end
end
