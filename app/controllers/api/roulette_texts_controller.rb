module Api
  class RouletteTextsController < Api::ApplicationController

    before_action :authenticate_user, except: [:health], unless: -> { request.options? }
    before_action :set_roulette_text, only: %i[update destroy]
    

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
          tickets: current_user.tickets
        }
      else
        render json: { error: "User not authenticated" }, status: :unauthorized
      end
    end

    def spin
      if current_user.use_ticket
        render json: { message: "ルーレットを回しました", tickets: current_user.tickets }
      else
        render json: { error: "チケット不足", tickets: current_user.tickets }, status: :forbidden
      end
    end    

    def update
      if @roulette_text.update(roulette_text_params)
        render json: @roulette_text, status: :ok
      else
        render json: @roulette_text.errors, status: :unprocessable_entity
      end
    end

    private
  
    def set_roulette_text
      @roulette_text = current_user.roulette_texts.find_by(number: params[:number])
      return if @roulette_text

      render json: { error: 'Roulette text not found' }, status: :not_found
    end

    def roulette_text_params
      params.require(:roulette_text).permit(:number, :text)
    end
  end
end