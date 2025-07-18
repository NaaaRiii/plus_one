module Api
  class GuestSessionsController < ApplicationController
    # POST /api/guest_login
    # どの環境でもワンクリックでゲスト用 JWT を取得できる簡易エンドポイント
    # 本番環境では RATE LIMIT や CAPTCHA など追加対策を推奨
    # Api::ApplicationController または他のコントローラで before_action :authenticate_user が定義されていない場合に
    # ArgumentError が発生しないよう、`raise: false` オプションを追加して安全にスキップする
    skip_before_action :authenticate_user, only: :create, raise: false

    def create
      guest_email    = ENV['GUEST_EMAIL']
      guest_password = ENV['GUEST_PASSWORD']

      return render json: { error: 'Guest login not configured' }, status: :internal_server_error unless guest_email.present? && guest_password.present?

      user = User.find_by(email: guest_email)

      return render json: { error: 'Guest user not found' }, status: :not_found unless user&.authenticate(guest_password)

      token = user.generate_auth_token
      render json: { token: token, user: { id: user.id, email: user.email, name: user.name } }, status: :ok
    end
  end
end 