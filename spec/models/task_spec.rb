require 'rails_helper'

RSpec.describe Task, type: :model do
  describe 'associations' do
    it 'belongs to small goal' do
      is_expected.to belong_to(:small_goal)
    end
  end

  describe 'validations' do
    it 'is valid with content and small goal' do
      task = build(:task)
      expect(task).to be_valid
    end

    it 'is invalid without content' do
      task = build(:task, content: nil)
      task.valid?
      expect(task.errors[:content]).to include("Please set the content")
    end

    it 'is invalid with content that is too long' do
      task = build(:task, content: "a" * 51)
      task.valid?
      expect(task.errors[:content]).to include("is too long (maximum is 50 characters)")
    end

    it 'is invalid without small goal' do
      task = build(:task, small_goal: nil)
      task.valid?
      expect(task.errors[:small_goal]).to include("must exist")
    end
  end

  describe 'instance methods' do
    describe '#user' do
      it 'returns the user of the small goal' do
        user = create(:user)
        goal = create(:goal, user: user)
        small_goal = create(:small_goal, goal: goal)
        task = create(:task, small_goal: small_goal)

        expect(task.user).to eq(user)
      end
    end

    describe '#mark_as_completed' do
      it 'marks the task as completed' do
        task = create(:task)
        task.mark_as_completed
        expect(task.completed).to be_truthy
      end

      it 'adds experience points to the user' do
        user = create(:user, total_exp: 0)
        goal = create(:goal, user: user)
        small_goal = create(:small_goal, goal: goal)
        task = create(:task, small_goal: small_goal)

        expect { task.mark_as_completed }.to change { user.reload.total_exp }.by(task.exp_for_task)
      end
    end

    describe '#exp_for_task' do
      it 'returns 1' do
        task = create(:task)
        expect(task.exp_for_task).to eq(1)
      end
    end
  end
end
