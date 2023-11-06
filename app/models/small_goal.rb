class SmallGoal < ApplicationRecord
  belongs_to  :goal
  has_many    :tasks, class_name: 'Task', dependent: :destroy
  accepts_nested_attributes_for :tasks, allow_destroy: true, reject_if: :all_blank

  def user
    goal.user
  end

  DIFFICULTY_MULTIPLIERS = {
    "ものすごく簡単" => 0.5,
    "簡単" => 0.7,
    "普通" => 1.0,
    "難しい" => 1.2,
    "とても難しい" => 1.5
  }

  #def complete
  #  if tasks.all?(&:completed) # すべてのタスクが完了しているか確認
  #    user.add_exp(exp_for_small_goal) # 経験値を加算
  #    return true
  #  else
  #    errors.add(:base, 'タスクが完了してません!')
  #    return false
  #  end
  #end

  def completed?
    tasks.all?(&:completed)
  end

  #def exp_for_small_goal
  #  total_tasks_exp = tasks.sum(&:exp_for_task)
  #  (total_tasks_exp * DIFFICULTY_MULTIPLIERS[difficulty]).to_i
  #end
end
