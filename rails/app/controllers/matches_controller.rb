class MatchesController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]

  def index
    @q       = Match.ransack(params[:q])
    @matches = @q.result(distinct: true)
                 .includes(:home_team, :away_team, :league, :prediction)
                 .order(scheduled_at: :asc)

    # Filters
    @matches = @matches.where(status: params[:status]) if params[:status].present?
    if params[:league_id].present?
      @matches = @matches.where(league_id: params[:league_id])
    end

    # Default: upcoming first, then recent
    if params[:q].blank? && params[:status].blank?
      @matches = @matches.where("scheduled_at >= ?", 3.days.ago)
    end

    @pagy, @matches = pagy(@matches, limit: 20)
    @leagues = League.active.order(:name)
  end

  def show
    @match = Match.includes(:home_team, :away_team, :league, :prediction, :match_statistic).find(params[:id])
    @head_to_head = @match.head_to_head(6)
    @home_form    = @match.home_team.recent_matches(5)
    @away_form    = @match.away_team.recent_matches(5)
  end

  def prediction
    @match = Match.find(params[:id])
    require_premium!

    @prediction = @match.prediction

    if @prediction.nil?
      GeneratePredictionsJob.perform_later(@match.id)
      flash[:notice] = "Vorhersage wird generiert – bitte in einigen Minuten erneut laden."
      redirect_to match_path(@match)
    end
  end
end
