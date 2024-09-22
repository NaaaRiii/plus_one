module Api
  class CurrentUsersController < ApplicationController
    include AuthHelper

    before_action :authenticate_user

    def show
      Rails.logger.debug "Current user: #{@current_user.inspect}"
      if @current_user
        latest_completed_goals_within_24h = @current_user.small_goals
                                              .where(completed: true)
                                              .where('completed_time > ?', 24.hours.ago)
                                              .order(completed_time: :desc)
                                              .limit(5)

        if latest_completed_goals_within_24h.empty?
          latest_completed_goal = @current_user.small_goals
                                    .where(completed: true)
                                    .order(completed_time: :desc)
                                    .first
          latest_completed_goals = latest_completed_goal.present? ? [latest_completed_goal] : []
        else
          latest_completed_goals = latest_completed_goals_within_24h
        end
      
        response_data = {
          id: @current_user.id,
          name: @current_user.name,
          #currentTitle: @current_user.current_title,
          email: @current_user.email,
          totalExp: @current_user.total_exp,
          rank: @current_user.calculate_rank,
          last_roulette_rank: @current_user.last_roulette_rank,
          goals: @current_user.goals.as_json(include: :small_goals),
          tasks: @current_user.tasks,
          rouletteTexts: @current_user.roulette_texts,
          tickets: @current_user.tickets,
          latestCompletedGoals: latest_completed_goals.as_json(only: [:id, :title, :completed_time])
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

    #def restart_without_title
    #  if @current_user
    #    @current_user.update(restart_without_title: true, total_exp: 0, current_title: nil)
    #    render json: @current_user
    #  else
    #    render json: { error: 'User not found' }, status: :not_found
    #  end
    #end

    #def restart_with_title
    #  if @current_user
    #    @current_user.update(legendary_hero_obtained_at: Time.current)
    #    render json: @current_user
    #  else
    #    render json: { error: 'User not found' }, status: :not_found
    #  end
    #end

    #private

    #def find_current_user
    #  token = request.headers['Authorization'].split(' ').last
    #  decoded_token = JWT.decode(token, Rails.application.secrets.secret_key_base, true, { algorithm: 'HS256' }).first
    #  User.find_by(id: decoded_token['user_id'])
    #rescue JWT::DecodeError
    #  nil
    #end
  end
end
