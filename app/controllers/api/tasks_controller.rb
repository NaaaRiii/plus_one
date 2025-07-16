module Api
  class TasksController < ApplicationController

    before_action :set_task, only: [:update_completed]

    def update_completed
      if @task.update(completed: params[:completed])
        render json: { message: 'Task updated successfully' }, status: :ok
      else
        render json: { error: 'Failed to update task' }, status: :unprocessable_entity
      end
    end

    private

    def set_task
      @task = Task.find(params[:id])
    end
  end
end