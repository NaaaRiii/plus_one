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
end