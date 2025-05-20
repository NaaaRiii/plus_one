class AddCognitoSubToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :cognito_sub, :string
    add_index :users, :cognito_sub, unique: true
  end
end
