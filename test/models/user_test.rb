require "test_helper"

class UserTest < ActiveSupport::TestCase

  def setup
    @user = User.new(name: "Example User", email: "user@example.com", password: "foobar", password_confirmation: "foobar")
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "name should be present" do
    @user.name = "     "
    assert_not @user.valid?
  end

  test "email should be present" do
    @user.email = "     "
    assert_not @user.valid?
  end

  test "name should not be too long" do
    @user.name = "a" * 51
    assert_not @user.valid?
  end

  test "email should not be too long" do
    @user.email = "a" * 244 + "@example.com"
    assert_not @user.valid?
  end

  test "email validation should accept valid addresses" do
    valid_addresses = %w[user@example.com USER@foo.COM A_US-ER@foo.bar.org
                         first.last@foo.jp alice+bob@baz.cn]
    valid_addresses.each do |valid_address|
      @user.email = valid_address
      assert @user.valid?, "#{valid_address.inspect} should be valid"
    end
  end

  test "email validation should reject invalid addresses" do
    invalid_addresses = %w[user@example,com user_at_foo.org user.name@example. foo@bar_baz.com foo@bar+baz.com foo@bar..com]
    invalid_addresses.each do |invalid_address|
      @user.email = invalid_address
      assert_not @user.valid?, "#{invalid_address.inspect} should be invalid"
    end
  end

  test "email addresses should be unique" do
    duplicate_user = @user.dup
    @user.save
    assert_not duplicate_user.valid?
  end

  test "email addresses should be saved as lowercase" do
    mixed_case_email = "Foo@ExAMPle.CoM"
    @user.email = mixed_case_email
    @user.save
    assert_equal mixed_case_email.downcase, @user.reload.email
  end

  test "password should be present (nonblank)" do
    @user.password = @user.password_confirmation = " " * 6
    assert_not @user.valid?
  end

  test "password should have a minimum length" do
    @user.password = @user.password_confirmation = "a" * 5
    assert_not @user.valid?
  end

  test "authenticated? should return false for a user with nil digest" do
    assert_not @user.authenticated?(:remember, '')
  end

  test "should create default roulette texts on create" do
    @user.save
    assert_equal 12, @user.roulette_texts.count
  end

  test "should generate a valid JWT token" do
    @user.save
    token = @user.generate_auth_token
    decoded_token = JWT.decode(token, Rails.application.secrets.secret_key_base, true, { algorithm: 'HS256' })
    assert_equal @user.id, decoded_token[0]["user_id"]
  end

  test "should remember the user" do
    @user.save
    remember_digest = @user.remember
    assert_not_nil @user.remember_digest
    assert_equal remember_digest, @user.remember_digest
  end

  test "should add experience points" do
    @user.total_exp = 100
    @user.add_exp(50)
    assert_equal 150, @user.total_exp
  end

  test "should calculate the correct rank" do
    @user.total_exp = 100
    assert_equal 9, @user.calculate_rank
  end

  test "should decrement tickets when using one" do
    @user.tickets = 3
    assert @user.use_ticket
    assert_equal 2, @user.tickets
  end

  test "should not decrement tickets if none left" do
    @user.tickets = 0
    assert_not @user.use_ticket
    assert_equal 0, @user.tickets
  end
end