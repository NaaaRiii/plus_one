class Task < ApplicationRecord
  belongs_to :user
  belongs_to :small_goal
end
