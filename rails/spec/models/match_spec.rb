require "rails_helper"

RSpec.describe Match, type: :model do
  it "derives result and outcome only for finished matches" do
    match = build(:match, status: :scheduled, home_score: 2, away_score: 1)
    expect(match.result).to be_nil

    match.status = :finished
    expect(match.result).to eq("2:1")
    expect(match.outcome).to eq("home")
  end

  it "lists upcoming matches in chronological order" do
    later  = create(:match, scheduled_at: 3.days.from_now)
    sooner = create(:match, scheduled_at: 1.day.from_now)
    create(:match, scheduled_at: 1.day.ago)
    expect(described_class.upcoming).to eq([sooner, later])
  end
end
