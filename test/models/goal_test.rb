require "test_helper"

class GoalTest < ActiveSupport::TestCase

  def setup
    # テスト実行前に毎回データをリセット
    SmallGoal.delete_all
    Goal.delete_all
    User.delete_all

    # ユーザーをセットアップし、Goal に紐づける
    @user = User.create!(name: "Example User", email: "user@example.com", password: "password")
    # Goal のセットアップ
    @goal = Goal.new(
      user: @user,
      title: "Learn Ruby on Rails",
      content: "Complete Rails tutorial by the end of the month.",
      deadline: 1.month.from_now
    )
  end

  # Goal オブジェクトが有効であることを確認
  test "should be valid" do
    puts @roulette_text.errors.full_messages if @roulette_text.invalid?  # デバッグ用出力
    assert @roulette_text.valid?
  end

  # タイトルが存在することを確認
  test "title should be present" do
    @goal.title = "   "
    assert_not @goal.valid?
    # 正規表現を括弧で囲む
    assert_match(/Please set the title/, @goal.errors[:title].join)
  end

  test "text should be present" do
    @roulette_text.number = 2 # ユニークな number を設定
    @roulette_text.text = " "  # 空白のみのテキスト
    assert_not @roulette_text.valid?
    assert_match(/Please set the content/, @roulette_text.errors.full_messages.join)
  end

  # タイトルの長さが50文字以内であることを確認
  test "title should not be too long" do
    @goal.title = "a" * 51
    assert_not @goal.valid?
  end

  # コンテンツが存在することを確認
  test "content should be present" do
    @goal.content = "   "
    assert_not @goal.valid?
    # 正規表現を括弧で囲む
    assert_match(/Please set the content/, @goal.errors[:content].join)
  end

  # コンテンツの長さが200文字以内であることを確認
  test "content should not be too long" do
    @goal.content = "a" * 201
    assert_not @goal.valid?
  end

  # 締め切りが存在することを確認
  test "deadline should be present" do
    @goal.deadline = nil
    assert_not @goal.valid?
    # 正規表現を括弧で囲む
    assert_match(/Please set the deadline/, @goal.errors[:deadline].join)
  end

  # ユーザーが関連付けられていることを確認
  test "should belong to a user" do
    @goal.user = nil
    assert_not @goal.valid?
  end

  # small_goals の関連付けテスト
  #test "should have many small_goals" do
  #  # small_goal を作成
  #  sg1 = @goal.small_goals.build(title: "Small Goal 1", difficulty: "Easy", deadline: 1.week.from_now, task: "Task 1")
  #  sg1.save!
  
  #  sg2 = @goal.small_goals.build(title: "Small Goal 2", difficulty: "Medium", deadline: 2.weeks.from_now, task: "Task 2")
  #  sg2.save!
  
  #  @goal.save
  
  #  assert_equal 2, @goal.small_goals.count
  #end

  test "should have many small_goals" do
    @goal.save
  
    # small_goal を作成し、バリデーションが失敗した際に例外を捕捉する
    assert_raises(ActiveRecord::RecordInvalid) do
      sg1 = @goal.small_goals.build(title: "Small Goal 1", difficulty: "Easy", deadline: 1.week.from_now, task: "Task 1")
      sg1.save!
    end
  
    assert_raises(ActiveRecord::RecordInvalid) do
      sg2 = @goal.small_goals.build(title: "Small Goal 2", difficulty: "Medium", deadline: 2.weeks.from_now, task: "Task 2")
      sg2.save!
    end
  
    # small_goals の数を確認
    assert_equal 0, @goal.small_goals.count  # エラー発生時には 0 であることを確認
  end

  # ネストされた属性の受け入れテスト
  test "should accept nested attributes for small_goals" do
    nested_attributes = {
      small_goals_attributes: [
        { title: "Small Goal 1", difficulty: "Easy", deadline: 1.week.from_now, task: "Task 1" },
        { title: "Small Goal 2", difficulty: "Medium", deadline: 2.weeks.from_now, task: "Task 2" }
      ]
    }
    @goal.update(nested_attributes)
    assert_equal 2, @goal.small_goals.size
  end

  # small_goals が存在しないことを許容するテスト
  test "should allow goal without small_goals" do
    @goal.save
    assert @goal.small_goals.empty?
  end

  # small_goals に task がない場合のバリデーションエラーを確認
  test "should not allow small_goals without task" do
    @goal.save

    assert_raises(ActiveRecord::RecordInvalid) do
      @goal.small_goals.create!(title: "Small Goal without Task", difficulty: "Easy", deadline: 1.week.from_now, task: nil)
    end
  end

  # completed_time メソッドのテスト
  test "completed_time should return updated_at if completed" do
    @goal.update(completed: true)
    assert_equal @goal.updated_at, @goal.completed_time
  end

  # completed_time メソッドが nil を返すことを確認
  test "completed_time should return nil if not completed" do
    @goal.update(completed: false)
    assert_nil @goal.completed_time
  end

  # small_goalのバリデーションにより、タスクが存在しないとエラーになることを確認
  test "should validate presence of at least one task for small goal" do
    @goal.save
  
    # small_goal インスタンスを作成するが tasks が空の場合にバリデーションエラーを確認
    small_goal = @goal.small_goals.build(title: "Small Goal without Tasks", difficulty: "Medium", deadline: 1.week.from_now)
  
    # バリデーション実行前の確認
    assert small_goal.tasks.empty?, "Tasks should be empty before validation"
  
    # バリデーションを実行し、エラーが発生することを確認
    assert_not small_goal.valid?
    assert_match(/You must have at least one task/, small_goal.errors.full_messages.join)
  
    # バリデーション実行後の確認
    assert_equal 1, small_goal.errors.count, "There should be one validation error"
  end

end
