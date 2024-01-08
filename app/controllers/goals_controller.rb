class GoalsController < ApplicationController
  include UserAuthenticatable
  include DifficultyMultiplier
  authenticate_user_for_actions [:new, :create]

  def index
    @goals = current_user.goals
  end

  def new
    @goal = Goal.new
    @goal.small_goals.build
  end

  def create
    @goal = current_user.goals.build(goal_params)
    if @goal.save
      redirect_to new_goal_small_goal_path(@goal), notice: "目標を保存しました。次にsmall_goalを作成しましょう。これは目標を達成するための小さな目標です。"
    else
      puts @goal.errors.full_messages
      render 'new'
    end
  end

  def show
    @goal = Goal.find(params[:id])
    @small_goals = @goal.small_goals
    @completed_small_goals = @small_goals.select(&:completed)
  end

  def edit
    @goal = Goal.find(params[:id])
    @small_goals = @goal.small_goals
  end

  def update
    @goal = Goal.find(params[:id])
    if @goal.update(goal_params)
      redirect_to @goal, notice: "Goal was successfully updated."
    else
      render 'edit'
    end
  end

  def destroy
    @goal = Goal.find(params[:id])
    @goal.destroy
    redirect_to goals_path, notice: "Goal was successfully deleted."
  end

  def complete
    @goal = Goal.find(params[:id])
    @goal.update(completed: true)
    if @goal.small_goals.any? { |sg| !sg.completed }
      flash[:alert] = "まだやるべきことがあるのでは？"
      render json: { success: false, message: "エラーが発生しました" }
      redirect_to goal_path(@goal)
    else
      @goal.update(completed: true)

      # small goalsのexpを集計し、3を掛ける
      total_exp_gained = @goal.small_goals.sum { |sg| sg.exp } * 3
      logger.debug "Small goals exp: " + @goal.small_goals.map { |sg| sg.exp.to_s }.join(", ")
      logger.debug "Total exp gained (3 times the sum): #{total_exp_gained}"
      # total_exp が nil の場合、0 を初期値として設定
      current_user.total_exp = current_user.total_exp.to_f + total_exp_gained

      current_user.save

      current_user.update_tickets

      Activity.create(
        user: current_user,
        goal: @goal,
        exp_gained: total_exp_gained,
        completed_at: Time.current
      )

      redirect_to dashboard_path, notice: "Goal 達成おめでとう! 獲得EXP: #{total_exp_gained}"

    end
  end

  private

  def goal_params
    params.require(:goal).permit(:title, :content, :deadline, small_goals_attributes: [:id, :title, :difficulty, :deadline, { tasks_attributes: [:id, :content] }])
  end

  def calculate_exp(goal)
    goal.small_goals.sum do |sg| 
      multiplier = DIFFICULTY_MULTIPLIERS[sg.difficulty] || 1.0
      sg.completed && sg.exp ? (sg.exp * multiplier) : 0
    end
  end
end

