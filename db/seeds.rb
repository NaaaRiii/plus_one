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
small_goal = goal.small_goals.create!(title: "Sample Small Goal", difficulty: "とても難しい", deadline: Time.zone.now + 5.days)

# サンプルTasks
20.times do |i|
  small_goal.tasks.create!(content: "Task #{i + 1}")
end

# サンプルGoal
goal = user.goals.create!(title: "Sample Goal", content: "This is a sample goal.", deadline: Time.zone.now + 7.days)

# サンプルSmall Goal
small_goal = goal.small_goals.create!(title: "Sample Small Goal", difficulty: "とても難しい", deadline: Time.zone.now + 5.days)

# サンプルTasks
20.times do |i|
  small_goal.tasks.create!(content: "Task #{i + 1}")
end

#user.update(total_exp: 0.0)
#user.update(last_roulette_rank: 0.0)
user.update(tickets: 2)

#User.find_each do |u|
#  u.update(tickets: 0)
#end

#user = User.find(7)

#RouletteText.create([
#  { number: 1, text: "サンプルテキスト1", user: user },
#  { number: 2, text: "サンプルテキスト2", user: user },
#  { number: 3, text: "サンプルテキスト3", user: user },
#  { number: 4, text: "サンプルテキスト4", user: user },
#  { number: 5, text: "サンプルテキスト5", user: user },
#  { number: 6, text: "サンプルテキスト6", user: user },
#  { number: 7, text: "サンプルテキスト7", user: user },
#  { number: 8, text: "サンプルテキスト8", user: user },
#  { number: 9, text: "サンプルテキスト9", user: user },
#  { number: 10, text: "サンプルテキスト10", user: user },
#  { number: 11, text: "サンプルテキスト11", user: user },
#  { number: 12, text: "サンプルテキスト12", user: user },
#])

(1..12).each do |number|
  RouletteText.find_or_create_by(number: number) do |roulette_text|
    roulette_text.content = "サンプルテキスト #{number}"
  end
end