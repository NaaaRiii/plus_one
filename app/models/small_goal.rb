class SmallGoal < ApplicationRecord
  before_save :calculate_exp
  include DifficultyMultiplier

  # 経験値の追加メソッド（難易度に応じて経験値を調整する）
  def add_experience(points, difficulty)
    multiplier = DIFFICULTY_MULTIPLIERS[difficulty] || 1.0
    self.total_exp += points * multiplier
  end

  belongs_to :goal
  has_many :tasks, class_name: 'Task', dependent: :destroy
  accepts_nested_attributes_for :tasks, allow_destroy: true, reject_if: :all_blank

  def user
    goal.user
  end

  def calculate_exp_for_small_goal(small_goal)
    task_count = small_goal.tasks.count
    difficulty_multiplier = DIFFICULTY_MULTIPLIERS[small_goal.difficulty]
    task_count * difficulty_multiplier
  end

  def completed?
    tasks.all?(&:completed)
  end

  private

  def calculate_exp
    # ここで exp 値の計算を行う
    self.exp = tasks.count * (DIFFICULTY_MULTIPLIERS[difficulty] || 1.0)
  end
end