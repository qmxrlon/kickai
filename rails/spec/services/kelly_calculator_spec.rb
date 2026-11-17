require "rails_helper"

RSpec.describe KellyCalculator do
  let(:prediction) { build(:prediction, home_win_prob: 0.5, draw_prob: 0.3, away_win_prob: 0.2) }

  it "returns nil without valid odds" do
    expect(described_class.new(prediction).calculate(decimal_odds: nil)).to be_nil
    expect(described_class.new(prediction).calculate(decimal_odds: 1.0)).to be_nil
  end

  it "uses quarter Kelly for the most likely outcome" do
    result = described_class.new(prediction).calculate(decimal_odds: 2.5)
    expect(result[:full_kelly]).to be_within(0.001).of(0.1667)
    expect(result[:kelly_fraction]).to be_within(0.001).of(0.0417)
  end

  it "never recommends a negative stake" do
    result = described_class.new(prediction).calculate(decimal_odds: 1.5)
    expect(result[:kelly_fraction]).to eq(0.0)
  end
end
