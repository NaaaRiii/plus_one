FactoryBot.define do
  factory :activity do
    association :user
    association :goal
    association :small_goal
  end
end