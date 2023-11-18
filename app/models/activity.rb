class Activity < ApplicationRecord
  belongs_to :user
  belongs_to :goal, optional: true
  belongs_to :small_goal, optional: true
end
