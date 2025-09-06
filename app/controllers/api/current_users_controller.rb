module Api
  class CurrentUsersController < ApplicationController

    before_action :authenticate_user, except: [:health], unless: -> { request.options? }

    def show
      if @current_user

        latest_completed_goals_within_24h = @current_user.small_goals
                                                         .where(completed: true)
                                                         .where('completed_time > ?', 24.hours.ago)
                                                         .order(completed_time: :desc)
                                                         .limit(10)
      
        latest_completed_goals = if latest_completed_goals_within_24h.empty?
                                   @current_user.small_goals
                                                .where(completed: true)
                                                .order(completed_time: :desc)
                                                .limit(10)
                                 else
                                   latest_completed_goals_within_24h
                                 end
      
        response_data = {
          id: @current_user.id,
          name: @current_user.name,
          email: @current_user.email,
          totalExp: @current_user.total_exp,
          rank: @current_user.calculate_rank,
          last_roulette_rank: @current_user.last_roulette_rank,
          goals: @current_user.goals.as_json(include: :small_goals),
          tasks: @current_user.tasks,
          rouletteTexts: @current_user.roulette_texts,
          tickets: @current_user.tickets,
          latestCompletedGoals: latest_completed_goals.as_json(only: [:id, :title, :completed_time]),
          is_guest: @current_user.guest?
        }
    
        render json: response_data
      else
        render json: { error: "User not found" }, status: :not_found
      end
    end

    def update_rank
      new_rank = params[:new_rank].to_i
      if @current_user.update(last_roulette_rank: new_rank)
        render json: { success: true, message: 'Rank updated successfully.' }
      else
        render json: { success: false, message: 'Failed to update rank.' }, status: :unprocessable_entity
      end
    end

    def update
      if @current_user
        if @current_user.update(user_params)
          render json: { 
            success: true, 
            message: 'User updated successfully.',
            user: {
              id: @current_user.id,
              name: @current_user.name,
              email: @current_user.email
            }
          }
        else
          render json: { 
            success: false, 
            message: 'Failed to update user.',
            errors: @current_user.errors.full_messages 
          }, status: :unprocessable_entity
        end
      else
        render json: { error: 'User not found' }, status: :not_found
      end
    end

    private

    def user_params
      params.require(:user).permit(:name)
    end
  end
end
