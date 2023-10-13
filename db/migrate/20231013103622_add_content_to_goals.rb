class AddContentToGoals < ActiveRecord::Migration[7.0]
  def change
    add_column :goals, :content, :text
  end
end
