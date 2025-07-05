require 'rails_helper'

RSpec.describe Activity, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      is_expected.to belong_to(:user)
    end

    it 'belongs to goal' do
      is_expected.to belong_to(:goal).optional
    end

    it 'belongs to small goal' do
      is_expected.to belong_to(:small_goal).optional
    end
  end

  describe 'validations' do
    it 'requires user_id' do
      is_expected.to validate_presence_of(:user_id)
    end

    it 'requires exp_gained to be greater than or equal to 0' do
      is_expected.to validate_numericality_of(:exp_gained).is_greater_than_or_equal_to(0)
    end
  end

  describe 'callbacks' do
    it 'sets completed_at before create' do
      activity = create(:activity, completed_at: nil)
      expect(activity.completed_at).to be_present
    end

    it 'does not override existing completed_at' do
      time = Time.current
      activity = create(:activity, completed_at: time)
      expect(activity.completed_at).to be_within(0.0001).of(time)
    end
  end
end