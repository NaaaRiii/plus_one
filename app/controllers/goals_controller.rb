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
      redirect_to dashboard_path, notice: "目標を保存しました。"
    else
      puts @goal.errors.full_messages
      render 'new'
    end
  end

  def show
    @goal = Goal.find(params[:id])
    @small_goals = @goal.small_goals
  end

  def edit
    @goal = Goal.find(params[:id])
    @small_goals = @goal.small_goals
  end

  def update
    @goal = Goal.find(params[:id])
    if @goal.update(goal_params)
      redirect_to dashboard_path, notice: "目標を更新しました。"
    else
      render 'edit'
    end
  end

  def destroy
    @goal = Goal.find(params[:id])
    @goal.destroy
    redirect_to dashboard_path, notice: "目標を削除しました。"
  end

  private

  def goal_params
    params.require(:goal).permit(:title, :content, :difficulty, :deadline, :small_goal, small_goals_attributes: [:id, :content, :_destroy])
  end

end
