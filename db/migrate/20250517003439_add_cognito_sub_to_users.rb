class AddCognitoSubToUsers < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!  # インデックスを非同期で張りたい場合

  def up
    # 1. null 許容でカラム追加
    add_column :users, :cognito_sub, :string, null: true

    # 2. 既存レコードを backfill
    #    - NULL や空文字列のままだとインデックス作成で失敗
    #    - UUID や SecureRandom で一意な値を入れる
    say_with_time "Backfilling cognito_sub" do
      User.where(cognito_sub: [nil, ""]).find_each(batch_size: 100) do |u|
        u.update_columns(cognito_sub: SecureRandom.uuid)
      end
    end

    # 3. ユニークインデックスを作成
    add_index :users, :cognito_sub, unique: true, algorithm: :inplace

    # 4. 将来的に null 禁止にするなら別マイグレーションで
    # change_column_null :users, :cognito_sub, false
  end

  def down
    remove_index :users, :cognito_sub
    remove_column :users, :cognito_sub
  end
end
