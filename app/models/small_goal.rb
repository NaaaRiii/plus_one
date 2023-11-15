class SmallGoal < ApplicationRecord
  RANK_UP_EXPERIENCE = [5, 10, 15, 20].freeze
  DIFFICULTY_MULTIPLIERS = {
    "ものすごく簡単" => 0.5,
    "簡単" => 0.7,
    "普通" => 1.0,
    "難しい" => 1.2,
    "とても難しい" => 1.5
  }.freeze

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

  def rank
    RANK_UP_EXPERIENCE.each_with_index do |exp, index|
      return index + 1 if total_exp < exp
    end
    RANK_UP_EXPERIENCE.size + 1
  end

  def total_exp
    tasks.count + calculate_exp
  end
end
