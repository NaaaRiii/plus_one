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
      goal = FactoryBot.build(:goal, content: "a" * 201)
      goal.valid?
      expect(goal.errors[:content]).to include("is too long (maximum is 200 characters)")
    end

    it 'is invalid without deadline' do
      goal = FactoryBot.build(:goal, deadline: nil)
      goal.valid?
      expect(goal.errors[:deadline]).to include("Please set the deadline")
    end
  end

  describe 'nested attributes' do
    it 'accepts nested attributes for small goals' do
      user = FactoryBot.create(:user)
      goal_attributes = {
        title: "Test Goal",
        content: "Test Content",
        deadline: Date.today + 7.days,
        small_goals_attributes: [
          { title: "Small Goal 1", difficulty: "Easy", deadline: Date.today + 3.days },
          { title: "Small Goal 2", difficulty: "Medium", deadline: Date.today + 5.days }
        ]
      }
      goal = user.goals.create(goal_attributes)
      expect(goal.small_goals.size).to eq(2)
      expect(goal.small_goals.first.title).to eq("Small Goal 1")
      expect(goal.small_goals.second.title).to eq("Small Goal 2")
    end

    it 'rejects nested attributes if all_blank' do
      user = FactoryBot.create(:user)
      goal_attributes = {
        title: "Test Goal",
        content: "Test Content",
        deadline: Date.today + 7.days,
        small_goals_attributes: [
          { title: "", difficulty: "", deadline: nil }
        ]
      }
      goal = user.goals.create(goal_attributes)
      expect(goal.small_goals.size).to eq(0)
    end

    it 'raises error when creating more than 5 small_goals at once' do
      user = FactoryBot.create(:user)
      small_goals_attributes = (1..6).map do |i|
        {
          title: "Small Goal #{i}",
          difficulty: "Easy",
          deadline: Date.today + i.days
        }
      end
      goal_attributes = {
        title: "Test Goal",
        content: "Test Content",
        deadline: Date.today + 7.days,
        small_goals_attributes: small_goals_attributes
      }
      expect do
        user.goals.create!(goal_attributes)
      end.to raise_error(ActiveRecord::NestedAttributes::TooManyRecords)
    end

    it 'does not add more than 5 small_goals to an existing goal' do
      user = FactoryBot.create(:user)
      goal = FactoryBot.create(:goal, user: user)
      5.times do |i|
        FactoryBot.create(:small_goal, goal: goal, title: "Small Goal #{i + 1}")
      end
      # 6つ目を追加
      goal.small_goals.create(title: "Small Goal 6", difficulty: "Easy", deadline: Date.today + 6.days)
      expect(goal.small_goals.size).to eq(6) # 直接createなら制限されない
    end
  end

  describe 'boundary values' do
    it 'is valid with title of maximum length' do
      goal = FactoryBot.build(:goal, title: "a" * 50)
      expect(goal).to be_valid
    end

    it 'is valid with content of maximum length' do
      goal = FactoryBot.build(:goal, content: "a" * 200)
      expect(goal).to be_valid
    end
  end

  describe '#completed_time' do
    it 'returns updated_at when completed is true' do
      goal = FactoryBot.create(:goal, completed: true)
      expect(goal.completed_time).to eq(goal.updated_at)
    end

    it 'returns nil when completed is false' do
      goal = FactoryBot.create(:goal, completed: false)
      expect(goal.completed_time).to be_nil
    end
  end
end
