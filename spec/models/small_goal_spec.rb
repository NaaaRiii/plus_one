require 'rails_helper'

RSpec.describe SmallGoal, type: :model do
  describe 'associations' do
    it "belongs to goal" do
      is_expected.to belong_to(:goal)
    end

    it "has many tasks" do
      is_expected.to have_many(:tasks).dependent(:destroy)
    end
  end

  describe 'validations' do
    it 'is valid if it has a title, difficulty, deadline, and at least one task' do
      goal = create(:goal) # Goalモデルのファクトリーを使って関連するGoalレコードを作成
      small_goal = build(:small_goal, goal: goal)
      small_goal.tasks.build(content: 'Test Task') # 少なくとも1つのTaskをこのテスト自身が追加している
      expect(small_goal).to be_valid
    end

    it 'is invalid if the title is empty' do
      goal = create(:goal)
      small_goal = build(:small_goal, goal: goal, title: nil)
      small_goal.tasks.build(content: 'Test Task')
      expect(small_goal).not_to be_valid
      expect(small_goal.errors[:title]).to include("Please set the title")
    end

    it 'is invalid if the title is too long' do
      goal = create(:goal)
      small_goal = build(:small_goal, goal: goal, title: "a" * 51)
      small_goal.tasks.build(content: 'Test Task')
      expect(small_goal).not_to be_valid
      expect(small_goal.errors[:title]).to include("is too long (maximum is 50 characters)")
    end

    it 'is invalid if the difficulty is empty' do
      goal = create(:goal)
      small_goal = build(:small_goal, goal: goal, difficulty: nil)
      small_goal.tasks.build(content: 'Test Task')
      expect(small_goal).not_to be_valid
      expect(small_goal.errors[:difficulty]).to include("Please set the difficulty")
    end

    it 'is invalid if the deadline is empty' do
      goal = create(:goal)
      small_goal = build(:small_goal, goal: goal, deadline: nil)
      small_goal.tasks.build(content: 'Test Task')
      expect(small_goal).not_to be_valid
      expect(small_goal.errors[:deadline]).to include("Please set the deadline")
    end

    it 'must be invalid if there are zero tasks' do
      goal = create(:goal)
      small_goal = build(:small_goal, goal: goal)
      expect(small_goal).not_to be_valid
      expect(small_goal.errors[:tasks]).to include("Please set at least one task")
    end
  end
end
