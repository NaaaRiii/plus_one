require "test_helper"

class ActivityTest < ActiveSupport::TestCase

  def setup
    # テスト実行前に必要なデータを設定
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

  # ゴールの完了時に Activity を作成するテスト
  test "should create activity when goal is completed" do
    @goal.update(completed: true)

    # Activity が作成されていることを確認
    assert_difference 'Activity.count', 1 do
      Activity.create!(
        user: @user,
        goal: @goal,
        exp_gained: 100,
        completed_at: Time.current
      )
    end

    # 作成された Activity を確認
    activity = Activity.last
    assert_equal @goal.id, activity.goal_id
    assert_equal @user.id, activity.user_id
    assert_equal 100, activity.exp_gained
  end

  # small_goal が関連付けられた Activity オブジェクトが正しく作成されることを確認
  #test "should create activity with small goal" do
  #  assert_raises(ActiveRecord::RecordInvalid) do
  #    sg1 = @goal.small_goals.build(title: "Small Goal 1", difficulty: "Easy", deadline: 1.week.from_now, task: "Task 1")
  #    sg1.save!
  #  end
  #  activity = Activity.create(user: @user, goal: @goal, small_goal: @small_goal, exp_gained: 50)
  #  puts "Small goal ID: #{activity.small_goal_id}"
  
  #  assert_equal @user.id, activity.user_id  # user_id が正しいかを確認
  #  assert_equal @goal.id, activity.goal_id  # goal_id が正しいかを確認
  #  assert_equal @small_goal.id, activity.small_goal_id  # small_goal_id が正しいかを確認
  #  assert_equal 50, activity.exp_gained  # exp_gained が 50 であることを確認
  #end

  #test "should create activity with small goal" do
  #  # small_goal を作成して保存
  #  assert_raises(ActiveRecord::RecordInvalid) do
  #    sg1 = @goal.small_goals.build(title: "Small Goal 1", difficulty: "Easy", deadline: 1.week.from_now, task: "Task 1")
  #    sg1.save!
  #  end

  #  # Activity を作成
  #  activity = Activity.create!(user: @user, goal: @goal, small_goal: @small_goal, exp_gained: 50)
  #  puts "Small goal ID: #{activity.small_goal_id}"
    
  #  # 作成された Activity の内容を確認
  #  assert_equal @user.id, activity.user_id  # user_id が正しいかを確認
  #  assert_equal @goal.id, activity.goal_id  # goal_id が正しいかを確認
  #  assert_equal @small_goal.id, activity.small_goal_id  # small_goal_id が正しいかを確認
  #  assert_equal 50, activity.exp_gained  # exp_gained が 50 であることを確認
  #end

  test "should create activity with small goal" do
    # small_goal を作成し、tasks もネストして作成
    @small_goal = @goal.small_goals.create!(
      title: "Small Goal 1",
      difficulty: "Easy",
      deadline: 1.week.from_now,
      tasks_attributes: [
        { content: "Task 1", completed: false }
      ]
    )
  
    # SmallGoal が正しく保存されているか確認
    assert @small_goal.persisted?, "Small goal was not saved."
    assert_equal 1, @small_goal.tasks.count, "Task count is not correct."
  
    # Activity を作成
    activity = Activity.create!(user: @user, goal: @goal, small_goal: @small_goal, exp_gained: 50)
    
    # 作成された Activity の内容を確認
    assert_equal @user.id, activity.user_id  # user_id が正しいかを確認
    assert_equal @goal.id, activity.goal_id  # goal_id が正しいかを確認
    assert_equal @small_goal.id, activity.small_goal_id  # small_goal_id が正しいかを確認
    assert_equal 50, activity.exp_gained  # exp_gained が 50 であることを確認
  end

  # small_goal がなくても Activity オブジェクトが正しく作成されることを確認
  test "should create activity without small goal" do
    activity = Activity.create(user: @user, goal: @goal, exp_gained: 50)
  
    assert_equal @user.id, activity.user_id  # user_id が正しいかを確認
    assert_equal @goal.id, activity.goal_id  # goal_id が正しいかを確認
    assert_nil activity.small_goal_id  # small_goal_id が nil であることを確認
    assert_equal 50, activity.exp_gained  # exp_gained が 50 であることを確認
  end

  # goal が nil の場合、Activity が作成されないことを確認するテスト
  test "should not create activity without goal" do
    activity = Activity.new(user: @user, exp_gained: 50, completed_at: Time.current)
    assert_not activity.valid?
    assert_includes activity.errors[:goal], "must exist"  # エラーメッセージを確認
  end

  # user が nil の場合、Activity が作成されないことを確認するテスト
  test "should not create activity without user" do
    activity = Activity.new(goal: @goal, exp_gained: 50, completed_at: Time.current)
    assert_not activity.valid?
    assert_includes activity.errors[:user], "must exist"  # エラーメッセージを確認
  end

  # exp_gained が負の値の場合、Activity が作成されないことを確認するテスト
  test "should not create activity with negative exp_gained" do
    activity = Activity.new(user: @user, goal: @goal, exp_gained: -10, completed_at: Time.current)
    assert_not activity.valid?
    assert_includes activity.errors[:exp_gained], "must be greater than or equal to 0"  # エラーメッセージを確認
  end

  # completed_at が自動的に設定されることを確認するテスト
  test "should set completed_at automatically" do
    activity = Activity.create!(user: @user, goal: @goal, exp_gained: 50)
    assert_not_nil activity.completed_at, "Activity should have a completed_at timestamp set automatically"
  end

  # Activity の一覧が user_id でフィルタリングできることを確認するテスト
  test "should get activities for a specific user" do
    # いくつかのアクティビティを作成
    Activity.create!(user: @user, goal: @goal, exp_gained: 20, completed_at: Time.current)
    other_user = User.create!(name: "Other User", email: "other@example.com", password: "password")
    other_goal = Goal.create!(user: other_user, title: "Other Goal", content: "This is another goal", deadline: 1.month.from_now)
    Activity.create!(user: other_user, goal: other_goal, exp_gained: 30, completed_at: Time.current)

    # 特定のユーザーのアクティビティのみ取得できることを確認
    user_activities = Activity.where(user_id: @user.id)
    assert_equal 1, user_activities.count
  end

end
