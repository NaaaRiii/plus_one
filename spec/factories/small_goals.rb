FactoryBot.define do
  factory :small_goal do
    title { "My Small Goal" }
    difficulty { "難しい" } 
    deadline { Date.today + 10.days }
    goal

    #taskが空ではある場合は無効というテストにしたければ、small goalにtaskがない状態のファクトリーを作成する必要がある
    #after(:build) do |small_goal|
    #  4.times do
    #    small_goal.tasks << build(:task, small_goal: small_goal)
    #  end
    #end
  end
end