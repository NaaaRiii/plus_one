# class GuestSessionsController < ApplicationController
#  def create
#    user = User.find_or_create_by(email: "guest@exapmle.com") do |user|
#      user.password = SecureRandom.urlsafe_base64
#      user.name = "ゲストユーザー"
#    end
#      session[:user_id] = user.id
#      session[:session_token] = user.session_token
#      flash[:success] = "ゲストユーザーとしてログインしました"
#      redirect_to root_url
#  end
# end

class GuestSessionsController < ApplicationController
  def create
    guest_user = User.find_or_create_by(email: "guest@example.com") do |user|
      user.password = SecureRandom.urlsafe_base64
      user.name = "ゲストユーザー"
    end
    session[:user_id] = guest_user.id
    session[:session_token] = guest_user.session_token
    flash[:success] = "ゲストユーザーとしてログインしました"
    redirect_to root_url
  end
end