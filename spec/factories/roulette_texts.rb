FactoryBot.define do
  factory :roulette_text do
    association :user
    number { rand(1..12) }
    text { "Roulette Text #{number}" }
  end
end 