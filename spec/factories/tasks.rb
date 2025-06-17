FactoryBot.define do
  factory :task do
    content { "Task Content" }
    completed { false } # 初期状態で未完了とする
    association :small_goal
  end
end