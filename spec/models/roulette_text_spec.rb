require 'rails_helper'

RSpec.describe RouletteText, type: :model do
  before(:each) do
    RouletteText.delete_all
    User.delete_all
  end

  describe 'associations' do
    it 'belongs to user' do
      is_expected.to belong_to(:user)
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      user = create(:user)
      RouletteText.where(user: user).delete_all
      roulette_text = build(:roulette_text, user: user, number: 1)
      expect(roulette_text).to be_valid
    end

    it 'is invalid without number' do
      user = create(:user)
      RouletteText.where(user: user).delete_all
      roulette_text = build(:roulette_text, user: user, number: nil)
      roulette_text.valid?
      expect(roulette_text.errors[:number]).to include("can't be blank")
    end

    it 'is invalid with number less than 1' do
      user = create(:user)
      RouletteText.where(user: user).delete_all
      roulette_text = build(:roulette_text, user: user, number: 0)
      roulette_text.valid?
      expect(roulette_text.errors[:number]).to include("must be between 1 and 12")
    end

    it 'is invalid with number greater than 12' do
      user = create(:user)
      RouletteText.where(user: user).delete_all
      roulette_text = build(:roulette_text, user: user, number: 13)
      roulette_text.valid?
      expect(roulette_text.errors[:number]).to include("must be between 1 and 12")
    end

    it 'is invalid with duplicate number for same user' do
      user = create(:user)
      # default texts include number 1 already
      duplicate = build(:roulette_text, user: user, number: 1)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:number]).to include("has already been taken")
    end

    it 'allows same number for different users' do
      user1 = create(:user)
      user2 = create(:user)
      # default texts include number 1 for both users
      text1 = user1.roulette_texts.find_by(number: 1)
      text2 = user2.roulette_texts.find_by(number: 1)
      expect(text1).to be_present
      expect(text2).to be_present
      expect(text1.number).to eq(text2.number)
    end

    it 'is invalid without text' do
      user = create(:user)
      RouletteText.where(user: user).delete_all
      roulette_text = build(:roulette_text, user: user, text: nil)
      roulette_text.valid?
      expect(roulette_text.errors[:text]).to include("Please set the content")
    end

    it 'is invalid with text longer than 50 characters' do
      user = create(:user)
      RouletteText.where(user: user).delete_all
      roulette_text = build(:roulette_text, user: user, text: "a" * 51)
      roulette_text.valid?
      expect(roulette_text.errors[:text]).to include("is too long (maximum is 50 characters)")
    end
  end

  describe 'default scope' do
    it 'orders by number ascending' do
      user = create(:user)
      RouletteText.where(user: user).delete_all
      create(:roulette_text, user: user, number: 3)
      create(:roulette_text, user: user, number: 1)
      create(:roulette_text, user: user, number: 2)

      expect(user.roulette_texts.order(nil).pluck(:number)).to eq([1, 2, 3])
    end
  end

  describe 'callbacks' do
    it 'normalizes text before save' do
      user = create(:user)
      RouletteText.where(user: user).delete_all
      roulette_text = create(:roulette_text, user: user, text: "  Hello   World  ", number: 5)
      expect(roulette_text.text).to eq("Hello World")
    end

    it 'handles nil text gracefully' do
      user = create(:user)
      RouletteText.where(user: user).delete_all
      roulette_text = build(:roulette_text, user: user, text: nil, number: 6)
      expect { roulette_text.save }.not_to raise_error
    end
  end
end