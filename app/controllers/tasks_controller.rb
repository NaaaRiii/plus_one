class TasksController < ApplicationController
  include UserAuthenticatable
  authenticate_user_for_actions [:new, :create]

  def new
  end

  def create
  end

  def edit
  end

  def update
    task = Task.find(params[:id])
    task.update(completed: params[:completed])
  end

  def destroy
  end

end
