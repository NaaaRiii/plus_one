class SmallGoalsController < ApplicationController
  before_action :set_goal
  before_action :set_small_goal, only: [:update]
  include UserAuthenticatable
  authenticate_user_for_actions [:new, :create]

  def new
    @goal = Goal.find(params[:goal_id])
    @small_goal = @goal.small_goals.build
    @small_goal.tasks.build
  end

  def create
    @goal = Goal.find(params[:goal_id])
    @small_goal = @goal.small_goals.build(small_goal_params)
    if @small_goal.save
      redirect_to goal_path(@goal), notice: "目標とsmall_goalを保存しました。確認してみましょう。"
    else
      puts @small_goal.errors.full_messages
      render 'new'
    end
  end

  def edit
    @goal = Goal.find(params[:goal_id])
    @small_goal = @goal.small_goals.find(params[:id])
  end

  def update
    if @small_goal.update(small_goal_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @goal, notice: "Small goal was successfully updated." }
      end
    else
      render :edit
    end
  end

  def complete
    small_goal = SmallGoal.find(params[:id])
    if small_goal.update(completed: true, completed_time: Time.current)
      # exp の計算
      exp_gained = calculate_exp_for_small_goal(small_goal)

      # total_exp が nil の場合、0 を初期値として設定
      current_user.total_exp += exp_gained.to_f
      current_user.save

      # Activity レコードを作成
      current_user.activities.create(
        goal_title: small_goal.goal.title,
        small_goal_title: small_goal.title,
        exp_gained: exp_gained
      )

      redirect_to dashboard_path, notice: "Small goal completed successfully!"
    else
      redirect_to dashboard_path, alert: "There was a problem completing the small goal."
    end
  end

  private

  def set_goal
    @goal = current_user.goals.find(params[:goal_id])
  end

  def set_small_goal
    @small_goal = @goal.small_goals.find(params[:id])
  end

  def small_goal_params
    params.require(:small_goal).permit(:title, :difficulty, :deadline, :completed, :completed_time, :task, tasks_attributes: [:id, :completed, :content, :_destroy])
  end

  def calculate_exp_for_small_goal(small_goal)
    task_count = small_goal.tasks.count
    difficulty_multiplier = DIFFICULTY_MULTIPLIERS[small_goal.difficulty]
    exp = (task_count * difficulty_multiplier).round(1)
    logger.debug "Calculating exp for small goal: #{small_goal.id}"
    logger.debug "Task count: #{task_count}, Difficulty multiplier: #{difficulty_multiplier}, Calculated exp: #{exp}"
    exp
  end
end
