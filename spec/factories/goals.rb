FactoryBot.define do
  factory :goal do
    title { "My Goal" }
    content { "My Goal Content" }
    deadline { Date.today + 7.days }
    user
  end
end