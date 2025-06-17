FactoryBot.define do
  factory :activity do
    association :user
    association :goal

    # ── small_goal は後段で紐付け ───────────────────
    small_goal { nil }

    exp_gained    { 10 }
    completed_at  { Time.zone.now.change(hour: 12) }   # JST 正午固定

    # 任意の日付を渡したい場合用のトレイト
    transient do
      date { nil }
    end

    trait :on_date do
      completed_at do
        (date || Date.current).in_time_zone('Asia/Tokyo').change(hour: 12)
      end
    end

    # ── ここがポイント ──────────────────────────────
    #   build でも create でも必ず同じ user/goal を共有した small_goal をセット
    #   small_goal を外から渡したい場合は override で上書きできる
    after(:build) do |activity, _evaluator|
      activity.small_goal ||= FactoryBot.build(
        :small_goal,
        goal: activity.goal
      )
    end
  end
end
