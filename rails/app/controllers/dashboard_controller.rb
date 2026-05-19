class DashboardController < ApplicationController
  def index
    @upcoming_matches  = Match.upcoming.includes(:home_team, :away_team, :league, :prediction).limit(10)
    @recent_matches    = Match.recent.includes(:home_team, :away_team, :league, :prediction).limit(5)
    @top_predictions   = Prediction.joins(:match)
                                   .where(matches: { status: :scheduled })
                                   .where("confidence_score >= ?", 65)
                                   .order(confidence_score: :desc)
                                   .includes(match: %i[home_team away_team league])
                                   .limit(3)
    @active_leagues    = League.active.includes(:sport).limit(8)
  end
end
