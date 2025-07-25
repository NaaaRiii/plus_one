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
  validate  :deadline_cannot_be_after_goal_deadline

  validate  :must_have_at_least_one_task
  

  def user
    goal.user
  end

  def calculate_exp_for_small_goal
    task_count = tasks.count
    difficulty_multiplier = DIFFICULTY_MULTIPLIERS[difficulty] || 1.0
    exp = (task_count * difficulty_multiplier).round(1)
    Rails.logger.debug "Calculating exp for small goal: #{id}"
    Rails.logger.debug "Task count: #{task_count}, Difficulty multiplier: #{difficulty_multiplier}, Calculated exp: #{exp}"
    exp
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

  def deadline_cannot_be_after_goal_deadline
    return if goal.nil?

    return unless deadline.present? && deadline > goal.deadline

    errors.add(:base, "Goalよりも後の日付を設定することはできません")
  end

end