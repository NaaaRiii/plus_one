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
      goal = FactoryBot.create(:goal, deadline: Date.today + 10.days)
      small_goal = FactoryBot.build(:small_goal, goal: goal, deadline: Date.today + 5.days)
      small_goal.tasks.build(content: 'Test Task')
      expect(small_goal).to be_valid
    end

    it 'is invalid if the title is empty' do
      goal = FactoryBot.create(:goal)
      small_goal = FactoryBot.build(:small_goal, goal: goal, title: nil)
      small_goal.tasks.build(content: 'Test Task')
      expect(small_goal).not_to be_valid
      expect(small_goal.errors[:title]).to include("Please set the title")
    end

    it 'is invalid if the title is too long' do
      goal = FactoryBot.create(:goal)
      small_goal = FactoryBot.build(:small_goal, goal: goal, title: "a" * 51)
      small_goal.tasks.build(content: 'Test Task')
      expect(small_goal).not_to be_valid
      expect(small_goal.errors[:title]).to include("is too long (maximum is 50 characters)")
    end

    it 'is invalid if the difficulty is empty' do
      goal = FactoryBot.create(:goal)
      small_goal = FactoryBot.build(:small_goal, goal: goal, difficulty: nil)
      small_goal.tasks.build(content: 'Test Task')
      expect(small_goal).not_to be_valid
      expect(small_goal.errors[:difficulty]).to include("Please set the difficulty")
    end

    it 'is invalid if the deadline is empty' do
      goal = FactoryBot.create(:goal)
      small_goal = FactoryBot.build(:small_goal, goal: goal, deadline: nil)
      small_goal.tasks.build(content: 'Test Task')
      expect(small_goal).not_to be_valid
      expect(small_goal.errors[:deadline]).to include("Please set the deadline")
    end

    it 'is invalid if there are zero tasks' do
      goal = FactoryBot.create(:goal)
      small_goal = FactoryBot.build(:small_goal, :without_tasks, goal: goal)
      expect(small_goal).not_to be_valid
      expect(small_goal.errors[:base]).to include("You must have at least one task.")
    end

    it 'is invalid if the small goal deadline is after the goal deadline' do
      goal = FactoryBot.create(:goal, deadline: Date.today + 7.days)
      small_goal = FactoryBot.build(:small_goal, goal: goal, deadline: Date.today + 8.days)
      small_goal.tasks.build(content: 'Test Task')
      expect(small_goal).not_to be_valid
      expect(small_goal.errors[:base]).to include("Goalよりも後の日付を設定することはできません")
    end

    it 'is valid if the small goal deadline is on or before the goal deadline' do
      goal = FactoryBot.create(:goal, deadline: Date.today + 7.days)
      small_goal = FactoryBot.build(:small_goal, goal: goal, deadline: Date.today + 7.days)
      small_goal.tasks.build(content: 'Test Task')
      expect(small_goal).to be_valid
    end
  end
end
