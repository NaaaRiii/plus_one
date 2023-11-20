class SmallGoal < ApplicationRecord
  before_save :calculate_exp

  DIFFICULTY_MULTIPLIERS = {
    "ものすごく簡単" => 0.5,
    "簡単" => 0.7,
    "普通" => 1.0,
    "難しい" => 1.2,
    "とても難しい" => 1.5
  }.freeze

  def calculate_rank_up_experience(max_rank = 120)
    experiences = [0, 5]
    increment = 10

    (3..max_rank).each do |rank|
      increment += 5 if (rank - 2) % 5 == 0
      experiences << experiences.last + increment
    end

    experiences
  end

  def rank
    total_exp = self.total_exp 
    calculate_rank_up_experience.each_with_index do |exp, index|
      return index + 1 if total_exp < exp
    end
    calculate_rank_up_experience.size + 1
  end

  #def rank
  #  RANK_UP_EXPERIENCE.each_with_index do |exp, index|
  #    return index + 1 if total_exp < exp
  #  end
  #  RANK_UP_EXPERIENCE.size + 1
  #end

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
