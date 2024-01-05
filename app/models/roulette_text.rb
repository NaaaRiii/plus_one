class RouletteText < ApplicationRecord
  belongs_to :user

  # 必要に応じてバリデーションを追加
  #validates :number, presence: true, uniqueness: { scope: :user_id }
  #validates :text, presence: true
end
