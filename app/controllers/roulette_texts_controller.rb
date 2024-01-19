class RouletteTextsController < ApplicationController
  before_action :set_roulette_text, only: [:show, :edit, :update, :destroy]

  def index
    @roulette_texts = RouletteText.all
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
    #@roulette_text = RouletteText.new(roulette_text_params)
    @roulette_text = current_user.roulette_texts.build(roulette_text_params)
    if @roulette_text.save
      render json: @roulette_text, status: :created
    else
      render json: @roulette_text.errors, status: :unprocessable_entity
    end
  end

  def edit
    @roulette_text = RouletteText.find(params[:id])
  end

  #def update
  #  if current_user.use_ticket
  #    if @roulette_text.update(roulette_text_params)
  #      render json: @roulette_text # または適切なリダイレクト
  #    else
  #      render json: @roulette_text.errors, status: :unprocessable_entity
  #    end
  #  else
  #    render json: { error: "You do not have enough tickets to edit." }, status: :forbidden
  #  end
  #end

  def update
    if current_user.use_ticket
      if @roulette_text.update(roulette_text_params)
        flash[:notice] = "Number: #{@roulette_text.number} を #{@roulette_text.text} に変更しました。"
        flash[:changed_roulette_text_id] = @roulette_text.id
        redirect_to edit_roulette_text_path(@roulette_text)
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

  private
    def set_roulette_text
      @roulette_text = RouletteText.find_by(number: params[:number])
    end

    def roulette_text_params
      params.require(:roulette_text).permit(:number, :text)
    end
end
