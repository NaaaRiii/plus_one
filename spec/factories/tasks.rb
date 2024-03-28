FactoryBot.define do
  factory :task do
    content { "Task content here" }
    completed { false } # 初期状態で未完了とする
    small_goal
  end
end