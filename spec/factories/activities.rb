FactoryBot.define do
  factory :activity do
    association :user
    association :goal
    association :small_goal
    exp_gained { 10 }
  end
end