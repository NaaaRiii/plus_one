class SmallGoal < ApplicationRecord
  belongs_to :goal
  has_many :tasks, class_name: 'Task', dependent: :destroy
  accepts_nested_attributes_for :tasks, allow_destroy: true, reject_if: proc { |attributes|
    attributes['content'].blank? && attributes['_destroy'].blank?
  }

  after_save :calculate_exp
  include DifficultyMultiplier

  validates :title, length: { maximum: 50 }, presence: { message: "Please set the title" }
  validates :difficulty, presence: { message: "Please set the difficulty" }
  validates :deadline, presence: { message: "Please set the deadline" }
  validate  :must_have_at_least_one_task

  # 経験値の追加メソッド（難易度に応じて経験値を調整する）
  def add_experience(points, difficulty)
    multiplier = DIFFICULTY_MULTIPLIERS[difficulty] || 1.0
    self.total_exp += points * multiplier
  end

  def user
    goal.user
  end

  def calculate_exp_for_small_goal(small_goal)
    task_count = small_goal.tasks.count
    difficulty_multiplier = DIFFICULTY_MULTIPLIERS[small_goal.difficulty]
    (task_count * difficulty_multiplier).round
  end  

  def completed?
    tasks.all?(&:completed)
  end

  private
  
  def calculate_exp
    new_exp = tasks.count * (DIFFICULTY_MULTIPLIERS[difficulty] || 1.0)
    return unless exp != new_exp

    self.exp = new_exp
    save if saved_changes?  # 直近の保存で変更があった場合のみ再保存
  end

  def must_have_at_least_one_task
    return unless tasks.reject(&:marked_for_destruction?).empty?

    errors.add(:base, "You must have at least one task.")
    
  end
end