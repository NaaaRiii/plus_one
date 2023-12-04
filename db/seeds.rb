# サンプルユーザーの検索または作成
user = User.find_or_create_by(email: "sample@example.com") do |u|
  u.name = "Sample User"
  u.password = "password"
  u.password_confirmation = "password"
  u.activated = true
  u.activated_at = Time.zone.now
end

# 既存のGoal、SmallGoal、Taskを削除
user.goals.destroy_all

# サンプルユーザー(dbリセットした場合はコメントアウトを外す)
#user = User.create!(name: "Sample User", email: "sample@example.com", password: "password", password_confirmation: "password", activated: true, activated_at: Time.zone.now)

# サンプルGoal
goal = user.goals.create!(title: "Sample Goal", content: "This is a sample goal.", deadline: Time.zone.now + 7.days)

# サンプルSmall Goal
small_goal = goal.small_goals.create!(title: "Sample Small Goal", difficulty: "難しい", deadline: Time.zone.now + 5.days)

# サンプルTasks
3.times do |i|
  small_goal.tasks.create!(content: "Task #{i + 1}")
end

#total_expを0に設定
user.update(total_exp: 0)