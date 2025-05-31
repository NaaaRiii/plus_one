module Api
  class RouletteTextsController < ApplicationController
    #include AuthHelper

    before_action :authenticate_user, except: [:health], unless: -> { request.options? }
    before_action :set_roulette_text, only: [:destroy]

    def index
      @roulette_texts = current_user.roulette_texts
      render json: @roulette_texts
    end

    def show
      @roulette_text = RouletteText.find_by(user_id: current_user.id, number: params[:number])
      if @roulette_text
        render json: @roulette_text
      else
        render json: { error: "Roulette text not found" }, status: :not_found
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

    def destroy
      @roulette_text.destroy
      head :no_content
    end

    def tickets
      if current_user
        render json: {
          play_tickets: current_user.play_tickets
        }
      else
        render json: { error: "User not authenticated" }, status: :unauthorized
      end
    end

    def spin
      if current_user.use_play_ticket
        render json: { message: "ルーレットを回しました", play_tickets: current_user.play_tickets }
      else
        render json: { error: "プレイチケットが足りません" }, status: :forbidden
      end
    end

    #def update
    #  if current_user.use_edit_ticket
    #    if @roulette_text.update(roulette_text_params)
    #      render json: { roulette_text: @roulette_text, edit_tickets: current_user.edit_tickets }
    #    else
    #      render json: @roulette_text.errors, status: :unprocessable_entity
    #    end
    #  else
    #    render json: { error: "編集チケットが足りません" }, status: :forbidden
    #  end
    #end

    private
  
    def set_roulette_text
      @roulette_text = current_user.roulette_texts.find_by(number: params[:number])

      return if @roulette_text

      render json: { error: 'Roulette text not found' }, status: :not_found
      
    end

    def roulette_text_params
      params.require(:roulette_text).permit(:text)
    end
  end
end