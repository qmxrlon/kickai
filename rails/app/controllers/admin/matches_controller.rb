module Admin
  class MatchesController < Admin::BaseController
    def index
      @q       = Match.ransack(params[:q])
      @pagy, @matches = pagy(
        @q.result.includes(:home_team, :away_team, :league, :prediction).order(scheduled_at: :desc),
        limit: 30
      )
    end

    def show
      @match = Match.includes(:home_team, :away_team, :league, :prediction).find(params[:id])
    end

    def trigger_prediction
      @match = Match.find(params[:id])
      GeneratePredictionsJob.perform_later(@match.id)
      flash[:notice] = "Vorhersage-Job wurde gestartet."
      redirect_to admin_match_path(@match)
    end

    def destroy
      @match = Match.find(params[:id])
      @match.destroy
      flash[:notice] = "Spiel gelöscht."
      redirect_to admin_matches_path
    end
  end
end
