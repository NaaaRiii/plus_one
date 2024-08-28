class Goal < ApplicationRecord
  belongs_to  :user
  has_many    :small_goals, class_name: 'SmallGoal', inverse_of: :goal, dependent: :destroy
  accepts_nested_attributes_for :small_goals, allow_destroy: true, reject_if: :all_blank, limit: 5

  validates :title, length: { maximum: 50 }, presence: { message: "Please set the title" }
  validates :content, length: { maximum: 1000 }, presence: { message: "Please set the content" }
  validates :deadline, presence: { message: "Please set the deadline" }

  def completed_time
    updated_at if completed
  end
  
end
