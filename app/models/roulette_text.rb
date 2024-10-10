class RouletteText < ApplicationRecord
  belongs_to :user

  # number は 1 から 12 の間で一意でなければならない
  validates :number, presence: true, uniqueness: { scope: :user_id }, inclusion: { in: 1..12, message: "must be between 1 and 12" }

  # text は必須で、長さが 50 文字以内である必要がある
  validates :text, presence: { message: "Please set the content" }, length: { maximum: 50 }

  # デフォルトの並び順を number の昇順に設定
  default_scope { order(:number) }

  # 保存前にテキストのフォーマットを整える
  before_save :normalize_text

  private

  # テキストのフォーマットを整えるメソッド
  def normalize_text
    self.text = text.strip.squeeze(" ") if text.present?
  end
end
