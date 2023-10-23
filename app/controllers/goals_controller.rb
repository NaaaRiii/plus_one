class GoalsController < ApplicationController
  include UserAuthenticatable
  authenticate_user_for_actions [:new, :create]

  def index
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

  #後ほど、editと合わせて実装する
  #def update
  #end

  private

  def goal_params
    params.require(:goal).permit(:title, :content, :difficulty, :deadline, :small_goal, small_goals_attributes: [:id, :content, :_destroy])
  end

end
