class Activity < ApplicationRecord
  #うまく活用できていない

  belongs_to :user
  belongs_to :goal
  belongs_to :small_goal, optional: true

  validates :user_id, presence: true
  validates :goal_id, presence: true
  validates :exp_gained, numericality: { greater_than_or_equal_to: 0 }

  # `completed_at` を自動設定する
  before_create :set_completed_at

  private

  def set_completed_at
    self.completed_at ||= Time.current
  end
end
