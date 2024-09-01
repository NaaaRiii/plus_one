module Api
  class RouletteTextsController < ApplicationController
    include AuthHelper

    before_action :set_roulette_text, only: [:show, :update, :destroy]
    before_action :authenticate_user

    def index
      @roulette_texts = current_user.roulette_texts
      render json: @roulette_texts
    end
    
    def show
      if @roulette_text
        render json: @roulette_text
      else
        render json: { error: "Not Found" }, status: :not_found
      end
    end

    def create
      @roulette_text = current_user.roulette_texts.build(roulette_text_params)
      if @roulette_text.save
        render json: @roulette_text, status: :created
      else
        render json: @roulette_text.errors, status: :unprocessable_entity
      end
    end

    def update
      if current_user.use_ticket
        if @roulette_text.update(roulette_text_params)
          render json: { roulette_text: @roulette_text, tickets: current_user.tickets }
        else
          render json: @roulette_text.errors, status: :unprocessable_entity
        end
      else
        render json: { error: "You do not have enough tickets to edit." }, status: :forbidden
      end
    end

    def destroy
      @roulette_text.destroy
      head :no_content
    end

    def tickets
      if @current_user
        render json: { tickets: @current_user.tickets }
      else
        render json: { tickets: error }
      end
    end

    private
    
    def set_roulette_text
      @roulette_text = RouletteText.find(params[:id])
    end

    def roulette_text_params
      params.require(:roulette_text).permit(:number, :text)
    end
  end
end
