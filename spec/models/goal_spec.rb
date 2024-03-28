require 'rails_helper'

RSpec.describe Goal, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      user = FactoryBot.create(:user)
      goal = FactoryBot.create(:goal, user: user)

      expect(goal.user).to eq(user)
    end

    it 'has many small goals' do
      goal = FactoryBot.create(:goal)
      small_goal1 = FactoryBot.create(:small_goal, goal: goal)
      small_goal2 = FactoryBot.create(:small_goal, goal: goal)

      expect(goal.small_goals).to include(small_goal1, small_goal2)
    end
  end

  describe 'validations' do
    it 'is valid with title, content, and deadline' do
      goal = FactoryBot.build(:goal)
      expect(goal).to be_valid
    end

    it 'is invalid without title' do
      goal = FactoryBot.build(:goal, title: nil)
      goal.valid?
      expect(goal.errors[:title]).to include("Please set the title")
    end

    it 'is invalid with title that is too long' do
      goal = FactoryBot.build(:goal, title: "a" * 51)
      goal.valid?
      expect(goal.errors[:title]).to include("is too long (maximum is 50 characters)")
    end

    it 'is invalid without content' do
      goal = FactoryBot.build(:goal, content: nil)
      goal.valid?
      expect(goal.errors[:content]).to include("Please set the content")
    end

    it 'is invalid with content that is too long' do
      goal = FactoryBot.build(:goal, content: "a" * 1001)
      goal.valid?
      expect(goal.errors[:content]).to include("is too long (maximum is 1000 characters)")
    end

    it 'is invalid without deadline' do
      goal = FactoryBot.build(:goal, deadline: nil)
      goal.valid?
      expect(goal.errors[:deadline]).to include("Please set the deadline")
    end
  end
end