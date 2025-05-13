#module Api
#  class SessionsController < ApplicationController
#    #include AuthHelper

#    def create
#      user = User.find_by(email: params[:email])
#      if user&.authenticate(params[:password])
#        token = JWT.encode({ user_id: user.id }, Rails.application.secret_key_base)
#        cookies.signed[:jwt] = { value: token, httponly: true, secure: Rails.env.production? }
#        render json: { success: true }
#      else
#        render json: { success: false, error: 'Invalid email or password' }, status: :unauthorized
#      end
#    end
  
#    def destroy
#      cookies.delete(:jwt, httponly: true, secure: Rails.env.production?)
#      render json: { success: true }
#    end

#    def check
#      if logged_in_user
#        render json: { logged_in: true, user: logged_in_user }
#      else
#        render json: { logged_in: false }
#      end
#    end

#    private

#    def generate_jwt(user)
#      payload = {
#        user_id: user.id,
#        jti: SecureRandom.uuid
#      }
#      JWT.encode(payload, Rails.application.secrets.secret_key_base, 'HS256')
#    end
#  end
#end


module Api
  class SessionsController < ApplicationController
    skip_before_action :authenticate_user!, only: [:create, :health]

    # POST /api/login
    def create
      user = User.find_by(email: params[:email])
      if user&.authenticate(params[:password])
        session[:user_id] = user.id
        render json: { message: 'ログイン成功' }, status: :ok
      else
        render json: { error: 'メールアドレスまたはパスワードが不正です' },
               status: :unauthorized
      end
    end

    # DELETE /api/logout
    def destroy
      reset_session
      head :no_content
    end

    # GET /api/current_user
    def show
      if current_user
        render json: current_user.slice(:id, :email, :name)
      else
        render json: { error: '未ログイン' }, status: :unauthorized
      end
    end

    # GET /api/health (必要な場合)
    def health
      head :ok
    end
  end
end
