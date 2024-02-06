FactoryBot.define do
  factory :task do
    content { "Task content here" } # `title`の代わりに`content`を使用
    completed { false } # 初期状態で未完了とする
    small_goal # `Task`は`SmallGoal`に属しているため、関連付ける
  end
end