class DashboardsController < ApplicationController
  include UserAuthenticatable
  authenticate_user_for_actions [:index]
  def index
    #render layout: false #application.html.erbを適用しない
  end
end
