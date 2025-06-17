FactoryBot.define do
  factory :user do
    name { "Do Test" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password" }
  end
end