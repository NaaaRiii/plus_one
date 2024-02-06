FactoryBot.define do
  factory :goal do
    title { "My Goal" }
    deadline { Date.today + 7.days }
    user
  end
end