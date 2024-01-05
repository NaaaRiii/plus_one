class RouletteTextsController < ApplicationController
  before_action :set_roulette_text, only: [:show, :edit, :update, :destroy]

  def show
    if @roulette_text
      render json: @roulette_text
    else
      render json: { error: "Not Found" }, status: :not_found
    end
  end

  def create
    #@roulette_text = RouletteText.new(roulette_text_params)
    @roulette_text = current_user.roulette_texts.build(roulette_text_params)
    if @roulette_text.save
      render json: @roulette_text, status: :created
    else
      render json: @roulette_text.errors, status: :unprocessable_entity
    end
  end

  def update
    if @roulette_text.update(roulette_text_params)
      render json: @roulette_text
    else
      render json: @roulette_text.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @roulette_text.destroy
    head :no_content
  end

  private
    def set_roulette_text
      @roulette_text = RouletteText.find_by(number: params[:number])
    end

    def roulette_text_params
      params.require(:roulette_text).permit(:number, :text)
    end
end
