class SessionsController < ApplicationController
  def new
  end

  #def create
  #  user = User.find_by(email: params[:session][:email].downcase)
  #  if user&.authenticate(params[:session][:password])
  #    if user.activated?
  #      forwarding_url = session[:forwarding_url]
  #      reset_session
  #      params[:session][:remember_me] == '1' ? remember(user) : forget(user)
  #      log_in user
  #      redirect_to forwarding_url || dashboard_path
  #    else
  #      message  = "Account not activated. "
  #      message += "Check your email for the activation link."
  #      flash[:warning] = message
  #      redirect_to root_url
  #    end
  #  else
  #    # エラーメッセージを作成する
  #    flash.now[:danger] = 'Invalid email/password combination'
  #    render 'new', status: :unprocessable_entity
  #  end
  #end

  def create
    user = User.find_by(email: params[:session][:email].downcase)
    if user&.authenticate(params[:session][:password])
      # ユーザーが有効な場合
      if user.activated?
        log_in user
        token = user.generate_auth_token
        
        respond_to do |format|
          format.html { redirect_to dashboard_path }
          format.json { render json: { token: token, user: { id: user.id, email: user.email } }, status: :ok }
        end
      else
        render json: { error: "Account not activated." }, status: :unauthorized
      end
    end
  end

  def destroy
    log_out if logged_in?
    redirect_to root_url, status: :see_other
  end
end
