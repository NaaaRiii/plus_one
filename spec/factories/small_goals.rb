FactoryBot.define do
  factory :small_goal do
    association :goal
    title       { 'Small Goal' }
    difficulty  { 'Easy' }
    deadline  { 2.days.from_now }
    completed { false }

    transient do
      tasks_count { 1 } # デフォルトで1つのタスクを作成
    end

    after(:build) do |small_goal, evaluator|
      small_goal.tasks << build_list(:task, evaluator.tasks_count, small_goal: small_goal)
    end

    trait :without_tasks do
      after(:build) do |small_goal, _evaluator|
        small_goal.tasks.clear
      end
    end

    
  end
end