class Task < ApplicationRecord
  belongs_to :user
  belongs_to :small_goal
  #belongs_to :goal

  # GPTの提案
  #def complete
  #  user.add_exp(exp_for_task)
  #end

  #def exp_for_task
  #  1
  #end

  # GPTの再提案
  def mark_as_completed
    update(completed: true)
    user.add_exp(exp_for_task) # タスクの完了時に経験値を加算
  end

  def exp_for_task
    1
  end
  
end
