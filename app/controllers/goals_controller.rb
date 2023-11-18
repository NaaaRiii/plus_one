class GoalsController < ApplicationController
  include UserAuthenticatable
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
      redirect_to goal_path(@goal)
    else
      @goal.update(completed: true)
      total_exp = calculate_exp(@goal)
      flash[:goal_completed] = "Goal 達成おめでとう! 獲得EXP: #{total_exp}"
      redirect_to dashboard_path
  
      Activity.create(
        user: current_user,
        goal: @goal,
        exp: total_exp,
        completed_at: Time.current
      )
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
