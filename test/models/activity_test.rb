require "test_helper"

class ActivityTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(name: "Example User", email: "user@example.com", password: "password")
    @goal = Goal.create!(
      user: @user,
      title: "Learn Rails",
      content: "Learn Rails to build a web application.",
      deadline: 1.month.from_now
    )
    @small_goal = @goal.small_goals.build(
      title: "Learn ActiveRecord",
      difficulty: "Easy",
      deadline: 1.week.from_now,
      task: "Initial Task"
    )
  end

  test "should create activity when goal is completed" do
    @goal.update(completed: true)

    assert_difference 'Activity.count', 1 do
      Activity.create!(user: @user, goal: @goal, exp_gained: 100, completed_at: Time.current)
    end

    activity = Activity.last
    assert_equal @goal.id, activity.goal_id
    assert_equal @user.id, activity.user_id
    assert_equal 100, activity.exp_gained
  end

  test "should create activity with small goal" do
    @small_goal = @goal.small_goals.create!(
      title: "Small Goal 1",
      difficulty: "Easy",
      deadline: 1.week.from_now,
      tasks_attributes: [
        { content: "Task 1", completed: false }
      ]
    )
    assert @small_goal.persisted?, "Small goal was not saved."
    assert_equal 1, @small_goal.tasks.count

    assert_difference 'Activity.count', 1 do
      activity = Activity.create!(user: @user, goal: @goal, small_goal: @small_goal, exp_gained: 50)
      assert_equal @user.id, activity.user_id
      assert_equal @goal.id, activity.goal_id
      assert_equal @small_goal.id, activity.small_goal_id
      assert_equal 50, activity.exp_gained
    end
  end

  test "should create activity without small goal" do
    assert_difference 'Activity.count', 1 do
      activity = Activity.create!(user: @user, goal: @goal, exp_gained: 50)
      assert_equal @user.id, activity.user_id
      assert_equal @goal.id, activity.goal_id
      assert_nil activity.small_goal_id
      assert_equal 50, activity.exp_gained
    end
  end

  test "should not create activity without user" do
    activity = Activity.new(goal: @goal, exp_gained: 50)
    assert_not activity.valid?
    assert_includes activity.errors[:user], "must exist"
  end

  test "should not create activity with negative exp_gained" do
    activity = Activity.new(user: @user, goal: @goal, exp_gained: -10)
    assert_not activity.valid?
    assert_includes activity.errors[:exp_gained], "must be greater than or equal to 0"
  end

  test "should set completed_at automatically" do
    assert_difference 'Activity.count', 1 do
      activity = Activity.create!(user: @user, goal: @goal, exp_gained: 50)
      assert_not_nil activity.completed_at
    end
  end

  test "should get activities for a specific user" do
    Activity.create!(user: @user, goal: @goal, exp_gained: 20, completed_at: Time.current)
    other_user = User.create!(name: "Other User", email: "other@example.com", password: "password")
    other_goal = Goal.create!(user: other_user, title: "Other Goal", content: "This is another goal", deadline: 1.month.from_now)
    Activity.create!(user: other_user, goal: other_goal, exp_gained: 30, completed_at: Time.current)

    user_activities = Activity.where(user_id: @user.id)
    assert_equal 1, user_activities.count
  end
end
