class Goal < ApplicationRecord
  belongs_to  :user
  has_many    :small_goals, class_name: 'SmallGoal', inverse_of: :goal, dependent: :destroy
  accepts_nested_attributes_for :small_goals, allow_destroy: true, reject_if: :all_blank, limit: 5

  DIFFICULTIES = ["ものすごく簡単", "簡単", "普通", "難しい", "とても難しい"].freeze
  validates :title,       length:     { maximum: 50 },       presence: true
  validates :content,     length:     { maximum: 1000 }
  validates :difficulty,  inclusion:  { in: DIFFICULTIES },  presence: true
  validates :deadline,                                       presence: true
  validates :small_goal,  length:     { maximum: 50 }

  #今はコメントアウト
  #def complete
  #  user.add_exp(total_exp_for_goal)
  #end

  #def total_exp_for_goal
  #  total_exp = tasks.sum(&:exp_for_task)
  #  total_exp += small_goals.sum(&:exp_for_small_goal)
  #  (total_exp * 1.2).to_i
  #end
end
