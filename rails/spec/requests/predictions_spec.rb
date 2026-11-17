require "rails_helper"

RSpec.describe "Predictions", type: :request do
  let(:prediction) { create(:prediction) }

  it "requires a premium account" do
    sign_in create(:user)
    get prediction_path(prediction)
    expect(response).to redirect_to(pricing_path)
  end

  it "renders the prediction for premium users" do
    sign_in create(:user, :premium)
    get prediction_path(prediction)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(prediction.match.home_team.name)
  end

  it "calculates a Kelly stake from the given odds" do
    sign_in create(:user, :premium)
    get prediction_path(prediction, odds: "2.50")
    # p = 0.5, b = 1.5 → full Kelly 0.1667 → ¼ Kelly ≈ 4.2 %
    expect(response.body).to include("4.2 %")
  end
end
