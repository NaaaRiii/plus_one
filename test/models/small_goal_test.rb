require "test_helper"

class SmallGoalTest < ActiveSupport::TestCase

  include DifficultyMultiplier

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
      deadline: 1.week.from_now
    )
  end

  # SmallGoal オブジェクトが有効であることを確認
  test "should be valid" do
    # タスクを追加して、バリデーションエラーが発生しないようにする
    @small_goal.tasks.build(content: "Initial Task")
    if @small_goal.invalid?
      puts @small_goal.errors.full_messages  # エラーがある場合、エラーメッセージを表示
    end
    assert @small_goal.valid?  # 有効であることを確認
  end

  # タイトルが存在することを確認
  test "title should be present" do
    @small_goal.title = "  "
    assert_not @small_goal.valid?
    assert_match(/Please set the title/, @small_goal.errors.full_messages.join)
  end

  # タイトルの長さが50文字以内であることを確認
  test "title should not be too long" do
    @small_goal.title = "a" * 51
    assert_not @small_goal.valid?
  end

  # 難易度が存在することを確認
  test "difficulty should be present" do
    @small_goal.difficulty = nil
    assert_not @small_goal.valid?
    assert_match(/Please set the difficulty/, @small_goal.errors.full_messages.join)
  end

  # 締め切りが存在することを確認
  test "deadline should be present" do
    @small_goal.deadline = nil
    assert_not @small_goal.valid?
    assert_match(/Please set the deadline/, @small_goal.errors.full_messages.join)
  end

  # 締め切りが Goal の締め切りを超えないことを確認
  test "deadline cannot be after goal deadline" do
    @small_goal.deadline = @goal.deadline + 1.day
    assert_not @small_goal.valid?
    assert_match(/Goalよりも後の日付を設定することはできません/, @small_goal.errors.full_messages.join)
  end

  # タスクが最低1つ存在しない場合にバリデーションエラーが発生することを確認
  test "should have at least one task" do
    # タスクなしの状態で保存を試みる
    @small_goal.tasks.clear
    assert_not @small_goal.valid?
    assert_match(/You must have at least one task/, @small_goal.errors.full_messages.join)
  end

  # タスクが1つでも存在すればバリデーションが成功することを確認
  test "should be valid with at least one task" do
    @small_goal.tasks.build(content: "Task 1")
    assert @small_goal.valid?
  end

  # ネストされたタスクの受け入れテスト
  test "should accept nested attributes for tasks" do
    nested_attributes = {
      tasks_attributes: [
        { content: "Task 1" },
        { content: "Task 2" }
      ]
    }
    @small_goal.update(nested_attributes)
    assert_equal 2, @small_goal.tasks.count
  end

  # ネストされたタスクの削除を許可するテスト
  test "should allow tasks to be destroyed" do
    task1 = @small_goal.tasks.build(content: "Task 1")
    task2 = @small_goal.tasks.build(content: "Task 2")
    @small_goal.save

    # task1 を削除し、task2 が残っていることを確認
    @small_goal.update(tasks_attributes: [{ id: task1.id, _destroy: "1" }])
    assert_equal 1, @small_goal.tasks.count
    assert_equal task2, @small_goal.tasks.first
  end

  # 完了の確認テスト
  test "should be completed if all tasks are completed" do
    @small_goal.tasks.build(content: "Task 1", completed: true)
    @small_goal.tasks.build(content: "Task 2", completed: true)
    @small_goal.save
    assert @small_goal.completed?
  end

  # 完了していないタスクがある場合、completed? は false を返すことを確認
  test "should not be completed if not all tasks are completed" do
    @small_goal.tasks.build(content: "Task 1", completed: true)
    @small_goal.tasks.build(content: "Task 2", completed: false)
    @small_goal.save
    assert_not @small_goal.completed?
  end

  # 経験値の計算が正しく行われることを確認
  test "should calculate experience based on tasks and difficulty" do
    @small_goal.tasks.build(content: "Task 1")
    @small_goal.difficulty = "Medium"
    @small_goal.save

    expected_exp = 1 * (DIFFICULTY_MULTIPLIERS["Medium"] || 1.0)
    assert_equal expected_exp, @small_goal.exp
  end
end
