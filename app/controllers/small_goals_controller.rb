class SmallGoalsController < ApplicationController
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

  private

  def small_goal_params
    params.require(:small_goal).permit(:title, :difficulty, :deadline, :task, tasks_attributes: [:id, :content, :_destroy])
  end

end
