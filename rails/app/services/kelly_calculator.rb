# Kelly Criterion calculator for optimal stake sizing.
#
# Kelly Fraction = (b * p - q) / b
#   where b = decimal_odds - 1 (net odds)
#         p = estimated win probability
#         q = 1 - p
#
# We use fractional Kelly (default 25%) to reduce variance.
class KellyCalculator
  FRACTION = 0.25  # 25% Kelly

  attr_reader :prediction

  def initialize(prediction)
    @prediction = prediction
  end

  # Returns recommended stake as fraction of bankroll (0.0 – 1.0)
  # decimal_odds: the bookmaker's decimal odds for the recommended outcome
  def calculate(decimal_odds: nil, bankroll: 1000.0)
    odds = decimal_odds.to_f
    return nil if odds <= 1.0

    prob = outcome_probability
    return nil if prob.nil? || prob <= 0 || prob >= 1

    b = odds - 1.0
    q = 1.0 - prob
    full_kelly = (b * prob - q) / b

    fraction = [full_kelly * FRACTION, 0.0].max
    {
      full_kelly:     full_kelly.round(4),
      kelly_fraction: fraction.round(4),
      recommended_pct: (fraction * 100).round(1),
      stake_for_1000: (fraction * bankroll).round(2)
    }
  end

  private

  def outcome_probability
    case prediction.top_outcome
    when :home then prediction.home_win_prob.to_f
    when :draw then prediction.draw_prob.to_f
    when :away then prediction.away_win_prob.to_f
    end
  end
end
