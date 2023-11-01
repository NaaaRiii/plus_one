class RenameContentToTitleInSmallGoals < ActiveRecord::Migration[7.0]
  def change
    rename_column :small_goals, :content, :title
  end
end
