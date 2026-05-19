module Admin
  class DashboardController < Admin::BaseController
    def index
      @user_count       = User.count
      @premium_count    = User.where(role: %i[premium admin]).count
      @match_count      = Match.count
      @prediction_count = Prediction.count
      @recent_users     = User.order(created_at: :desc).limit(5)
      @upcoming_matches = Match.upcoming.includes(:home_team, :away_team, :league).limit(10)
    end
  end
end
