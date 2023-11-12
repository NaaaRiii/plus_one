class SmallGoal < ApplicationRecord
  belongs_to  :goal
  has_many    :tasks, class_name: 'Task', dependent: :destroy
  accepts_nested_attributes_for :tasks, allow_destroy: true, reject_if: :all_blank

  def user
    goal.user
  end

  def calculate_exp
    difficulty_multiplier = {
      "ものすごく簡単" => 0.5,
      "簡単" => 0.7,
      "普通" => 1.0,
      "難しい" => 1.2,
      "とても難しい" => 1.5
    }
    self.tasks.count * difficulty_multiplier[self.difficulty]
  end

  def completed?
    tasks.all?(&:completed)
  end

  #def exp_for_small_goal
  #  total_tasks_exp = tasks.sum(&:exp_for_task)
  #  (total_tasks_exp * DIFFICULTY_MULTIPLIERS[difficulty]).to_i
  #end
end
