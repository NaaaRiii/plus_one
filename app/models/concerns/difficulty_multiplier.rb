module DifficultyMultiplier
  DIFFICULTY_MULTIPLIERS = {
    "ものすごく簡単" => 0.5,
    "簡単" => 0.7,
    "普通" => 1.0,
    "難しい" => 1.2,
    "とても難しい" => 1.5
  }.freeze

  def get_multiplier(difficulty)
    DIFFICULTY_MULTIPLIERS[difficulty]
  end
end