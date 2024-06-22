require 'rails_helper'

RSpec.describe User, type: :model do
  before do
    @user = FactoryBot.build(:user, name: "Example User", email: "user@example.com", password: "foobar", password_confirmation: "foobar")
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(@user).to be_valid
    end

    it 'is not valid without a name' do
      @user.name = nil
      expect(@user).not_to be_valid
    end

    it 'is not valid without an email' do
      @user.email = nil
      expect(@user).not_to be_valid
    end

    it 'is not valid with a name too long' do
      @user.name = "a" * 51
      expect(@user).not_to be_valid
    end

    it 'is not valid with an email too long' do
      @user.email = "#{'a' * 244}@example.com"
      expect(@user).not_to be_valid
    end

    it 'accepts valid email addresses' do
      valid_addresses = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org first.last@foo.jp alice+bob@baz.cn]
      valid_addresses.each do |valid_address|
        @user.email = valid_address
        expect(@user).to be_valid, "#{valid_address.inspect} should be valid"
      end
    end

    it 'rejects invalid email addresses' do
      invalid_addresses = %w[user@example,com user_at_foo.org user.name@example. foo@bar_baz.com foo@bar+baz.com foo@bar..com]
      invalid_addresses.each do |invalid_address|
        @user.email = invalid_address
        expect(@user).not_to be_valid, "#{invalid_address.inspect} should be invalid"
      end
    end

    it 'is not valid with duplicate email addresses' do
      duplicate_user = @user.dup
      @user.save
      expect(duplicate_user).not_to be_valid
    end

    it 'saves email addresses as lowercase' do
      mixed_case_email = "Foo@ExAMPle.CoM"
      @user.email = mixed_case_email
      @user.save
      expect(@user.reload.email).to eq mixed_case_email.downcase
    end

    it 'is not valid with a blank password' do
      @user.password = @user.password_confirmation = " " * 6
      expect(@user).not_to be_valid
    end

    it 'is not valid with a password too short' do
      @user.password = @user.password_confirmation = "a" * 5
      expect(@user).not_to be_valid
    end
  end

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
      goal = FactoryBot.create(:goal, user: @user)
      small_goal = FactoryBot.create(:small_goal, goal: goal)
      task1 = small_goal.tasks.first

      expect(@user.tasks).to include(task1)
    end
  end

  describe 'methods' do
    before do
      @user.save # ユーザーをデータベースに保存
    end

    it 'authenticated? returns false for a user with nil digest' do
      expect(@user.authenticated?(:remember, '')).to be_falsey
    end

    it 'generate_auth_token should return a token' do
      token = @user.generate_auth_token
      expect(token).not_to be_nil
    end

    it 'add_exp should increase total_exp' do
      @user.total_exp = 0
      @user.add_exp(10)
      expect(@user.total_exp).to eq 10
    end

    it 'calculate_rank should return correct rank' do
      @user.total_exp = 0
      expect(@user.calculate_rank).to eq 1
    end

    it 'update_rank should update last_roulette_rank' do
      @user.total_exp = 150
      @user.update_rank
      @user.reload # データベースから最新の値を取得する
      expect(@user.last_roulette_rank).not_to be_nil
    end

    it 'update_tickets should increment tickets' do
      @user.total_exp = 150
      @user.tickets = 0
      @user.update_tickets
      @user.reload # データベースから最新の値を取得する
      expect(@user.tickets).to eq 1
    end

    it 'use_ticket should decrement tickets' do
      @user.tickets = 1
      @user.use_ticket
      @user.reload # データベースから最新の値を取得する
      expect(@user.tickets).to eq 0
    end

    it 'activate should set activated to true' do
      @user.save
      @user.activate
      expect(@user.activated).to be true
    end

    it 'send_activation_email should send email' do
      @user.save
      expect {
        @user.send_activation_email
      }.to change { ActionMailer::Base.deliveries.size }.by(1)
    end
  end

  describe 'callbacks' do
    it 'downcase_email should downcase email before save' do
      mixed_case_email = "Foo@ExAMPle.CoM"
      @user.email = mixed_case_email
      @user.save
      expect(@user.reload.email).to eq mixed_case_email.downcase
    end

    it 'create_activation_digest should set activation_token and activation_digest' do
      @user.save
      expect(@user.activation_token).not_to be_nil
      expect(@user.activation_digest).not_to be_nil
    end
  end
end
