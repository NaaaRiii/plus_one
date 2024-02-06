require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it 'has many goals' do
      user = FactoryBot.create(:user)
      goal1 = FactoryBot.create(:goal, user: user)
      goal2 = FactoryBot.create(:goal, user: user)

      expect(user.goals).to include(goal1, goal2)
    end

    it 'has many small goals through goals' do
      user = FactoryBot.create(:user)
      goal = FactoryBot.create(:goal, user: user)
      small_goal1 = FactoryBot.create(:small_goal, goal: goal)
      small_goal2 = FactoryBot.create(:small_goal, goal: goal)

      expect(user.small_goals).to include(small_goal1, small_goal2)
    end

    it 'has many tasks through small goals' do
      user = FactoryBot.create(:user)
      goal = FactoryBot.create(:goal, user: user)
      small_goal = FactoryBot.create(:small_goal, goal: goal)
      task1 = FactoryBot.create(:task, small_goal: small_goal, content: "Task 1 content")
      task2 = FactoryBot.create(:task, small_goal: small_goal, content: "Task 2 content")

      expect(user.tasks).to include(task1, task2)
    end
  end
end
