require "test_helper"

class TaskTest < ActiveSupport::TestCase
  def setup
    # テスト実行前に必要なデータを設定
    @user = User.create!(name: "Example User", email: "user@example.com", password: "password")
    @goal = Goal.create!(
      user: @user,
      title: "Learn Rails",
      content: "Learn Rails to build a web application.",
      deadline: 1.month.from_now
    )

    # SmallGoal に最低1つのタスクを追加してバリデーションエラーを回避
    @small_goal = @goal.small_goals.create!(
      title: "Learn ActiveRecord",
      difficulty: "Easy",
      deadline: 1.week.from_now,
      tasks_attributes: [{ content: "Initial Task" }] # タスクを追加
    )

    # Task インスタンスを作成
    @task = @small_goal.tasks.build(content: "Initial Task")
  end

  # Task オブジェクトが有効であることを確認
  test "should be valid" do
    assert @task.valid?
  end

  # content が存在することを確認
  test "content should be present" do
    @task.content = "  "
    assert_not @task.valid?
    assert_match(/Please set the content/, @task.errors.full_messages.join)
  end

  # content の長さが 50 文字以内であることを確認
  test "content should not be too long" do
    @task.content = "a" * 51
    assert_not @task.valid?
  end

  # user メソッドの動作確認
  test "should return correct user" do
    assert_equal @user, @task.user
  end

  # mark_as_completed メソッドの動作確認
  test "should mark task as completed" do
    @task.save
    assert_not @task.completed, "Task should initially not be completed"

    # タスクを完了状態にする
    @task.mark_as_completed
    assert @task.completed, "Task should be marked as completed"
  end

  # mark_as_completed メソッドがユーザーの経験値を加算することを確認
  test "should add experience to user when task is completed" do
    @task.save

    initial_exp = @user.total_exp
    @task.mark_as_completed

    # exp_for_task メソッドで定義されている経験値がユーザーに加算されることを確認
    assert_equal initial_exp + @task.exp_for_task, @user.total_exp
  end

  # exp_for_task メソッドが正しい経験値を返すことを確認
  test "exp_for_task should return correct value" do
    assert_equal 1, @task.exp_for_task
  end

  # small_goal が存在しない状態で user メソッドを呼び出したときの動作を確認
  test "should return nil user if small_goal is nil" do
    @task.small_goal = nil
    assert_nil @task.user
  end
end
