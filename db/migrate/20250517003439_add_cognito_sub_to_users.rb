class AddCognitoSubToUsers < ActiveRecord::Migration[7.0]
  def change
    # 1) まずは null を許容してカラムを追加
    add_column :users, :cognito_sub, :string, null: true

    # 2) 一意インデックスを作成
    add_index :users, :cognito_sub, unique: true
  end
end
