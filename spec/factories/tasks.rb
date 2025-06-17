FactoryBot.define do
  factory :task do
    # belongs_to :small_goal のみ
    association :small_goal

    content   { 'Sample task' }
    #deadline  { 1.day.from_now }
    completed { false }
  end
end