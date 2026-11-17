class PredictionsController < ApplicationController
  before_action :require_premium!

  def show
    @prediction = Prediction.includes(match: %i[home_team away_team league]).find(params[:id])
    @match      = @prediction.match
    @kelly      = KellyCalculator.new(@prediction).calculate(decimal_odds: params[:odds]) if params[:odds].present?
  end
end
