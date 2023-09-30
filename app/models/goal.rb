class Goal < ApplicationRecord
  belongs_to :user
  has_many :small_goals
end
