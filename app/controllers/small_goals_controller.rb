class SmallGoalsController < ApplicationController
  include UserAuthenticatable
  authenticate_user_for_actions [:new, :create]

  def new
  end

  def create
  end
end
