module Api
  class UsersController < ApplicationController
    before_action :find_current_user, only: [:show]
    before_action :authenticate_user, except: [:health], unless: -> { request.options? }

    def show
      # 認可: URL で渡された id と認証済みユーザーが一致するかチェック
      return render json: { error: 'User not found' }, status: :not_found unless @current_user && @current_user.id == params[:id].to_i

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
  
        # レスポンスデータの構造を作成
        response_data = {
          name: @current_user.name,
          totalExp: @current_user.total_exp,
          rank: @current_user.calculate_rank,
          tickets: @current_user.tickets,
          #currentTitle: @current_user.current_title,
          latestCompletedGoals: latest_completed_goals.as_json(only: [:id, :title, :completed_time])
        }
  
        render json: response_data
      else
        render json: { error: "User not found" }, status: :not_found
      end
    end

    def withdrawal
      # authenticate_userで設定された@current_userを使用
      return render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
      
      user_id = @current_user.id
      
      begin
        ActiveRecord::Base.transaction do
          @current_user.destroy!
          Rails.logger.info "User withdrawal completed: user_id=#{user_id}"
        end

        render json: {
          message: "ユーザーの退会処理が完了しました",
          status: "success"
        }, status: :ok

      rescue ActiveRecord::RecordNotDestroyed => e
        Rails.logger.error "User withdrawal failed: user_id=#{user_id}, error=#{e.message}"
        render json: {
          error: "退会処理中にエラーが発生しました",
          status: "error"
        }, status: :internal_server_error
      rescue StandardError => e
        Rails.logger.error "User withdrawal failed: user_id=#{user_id}, error=#{e.message}"
        render json: {
          error: "退会処理中にエラーが発生しました",
          status: "error"
        }, status: :internal_server_error
      end
    end

    private

    def find_current_user
      @current_user = User.find_by(id: params[:id])
    end
  end
end
