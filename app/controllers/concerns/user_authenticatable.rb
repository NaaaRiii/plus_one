module UserAuthenticatable
  extend ActiveSupport::Concern
  #include AuthHelper

  included do
    before_action :authenticate_user, except: [:health], unless: -> { request.options? }
  end

  class_methods do
    def authenticate_user_for_actions(actions = [])
      before_action :logged_in_user, only: actions
    end
  end

  private

  def logged_in_user
    return if logged_in?

    store_location
    render json: { error: "Please log in." }, status: :unauthorized
    
  end

  def logged_in?
    @current_user.present?
  end

  def correct_user
    @user = User.find(params[:id])
    render json: { error: "Not authorized." }, status: :forbidden unless @current_user == @user
  end

  def store_location
    session[:forwarding_url] = request.original_url if request.get?
  end
end
