require "rails_helper"

RSpec.describe "Matches", type: :request do
  let(:match) { create(:match) }

  describe "GET /matches" do
    it "is public" do
      match
      get matches_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(match.home_team.name)
    end
  end

  describe "GET /matches/:id" do
    it "shows the match and a premium teaser to guests" do
      create(:prediction, match: match)
      get match_path(match)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Premium erforderlich")
    end

    it "shows the full prediction to premium users" do
      create(:prediction, match: match)
      sign_in create(:user, :premium)
      get match_path(match)
      expect(response.body).to include("Ausgangswahrscheinlichkeit")
    end
  end

  describe "GET /matches/:id/prediction" do
    it "sends free users to the pricing page without starting a job" do
      sign_in create(:user)
      expect { get prediction_match_path(match) }.not_to have_enqueued_job(GeneratePredictionsJob)
      expect(response).to redirect_to(pricing_path)
    end

    it "queues a prediction for premium users when none exists" do
      sign_in create(:user, :premium)
      expect { get prediction_match_path(match) }.to have_enqueued_job(GeneratePredictionsJob).with(match.id)
      expect(response).to redirect_to(match_path(match))
    end

    it "redirects premium users to an existing prediction" do
      prediction = create(:prediction, match: match)
      sign_in create(:user, :premium)
      get prediction_match_path(match)
      expect(response).to redirect_to(prediction_path(prediction))
    end
  end
end
