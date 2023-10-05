class Goal < ApplicationRecord
  belongs_to  :user
  has_many    :small_goals, class_name: 'SmallGoal', dependent: :destroy
  # GPT曰く以下は冗長で不要
  #has_many   :small_goals
  #has_many   :tasks

  # GPTの提案
  def complete
    user.add_exp(total_exp_for_goal)
  end

  def total_exp_for_goal
    total_exp = tasks.sum(&:exp_for_task)
    total_exp += small_goals.sum(&:exp_for_small_goal)
    (total_exp * 1.2).to_i
  end
end
