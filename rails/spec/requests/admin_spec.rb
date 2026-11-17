require "rails_helper"

RSpec.describe "Admin area", type: :request do
  let!(:match) { create(:match) }

  it "is not accessible for normal users" do
    sign_in create(:user)
    get admin_root_path
    expect(response).to redirect_to(root_path)
  end

  context "as admin" do
    before { sign_in create(:user, :admin) }

    it "renders every admin page" do
      user = create(:user)
      [admin_root_path, admin_users_path, admin_user_path(user), edit_admin_user_path(user),
       admin_matches_path, admin_match_path(match), admin_leagues_path, new_admin_league_path,
       edit_admin_league_path(match.league)].each do |path|
        get path
        expect(response).to have_http_status(:ok), "expected #{path} to render"
      end
    end

    it "updates a user's role" do
      user = create(:user)
      patch admin_user_path(user), params: { user: { role: "premium" } }
      expect(user.reload).to be_premium
    end

    it "creates a league" do
      expect {
        post admin_leagues_path, params: { league: { name: "Bundesliga", country: "Deutschland",
                                                     external_id: "BL1", sport_id: match.league.sport_id } }
      }.to change(League, :count).by(1)
    end
  end
end
