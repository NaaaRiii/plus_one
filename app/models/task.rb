class Task < ApplicationRecord
  belongs_to :small_goal

  validates :content, length: { maximum: 50 }, presence: { message: "Please set the content" }
  
  def user
    # small_goal が存在しない場合には nil を返す
    return nil unless small_goal

    small_goal.goal.user
  end

  def mark_as_completed
    update(completed: true)
    user.add_exp(exp_for_task) # タスクの完了時に経験値を加算
  end

  def exp_for_task
    1
  end

end
