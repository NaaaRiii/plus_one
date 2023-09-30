class SmallGoal < ApplicationRecord
  belongs_to :user
  belongs_to :goal
  has_many :tasks
end
