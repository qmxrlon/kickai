class Prediction < ApplicationRecord
  belongs_to :match

  # Outcome probabilities (0.0 – 1.0)
  # home_win_prob, draw_prob, away_win_prob

  # Over/Under stored in JSONB: { "1.5" => 0.85, "2.5" => 0.61, "3.5" => 0.38 }
  # btts_prob, xg_home, xg_away

  # Confidence 0-100, value_rating 1-5
  # recommended_bet, kelly_fraction

  validates :match_id, uniqueness: true

  # Recommended outcome as symbol
  def top_outcome
    probs = {
      home: home_win_prob.to_f,
      draw: draw_prob.to_f,
      away: away_win_prob.to_f
    }
    probs.max_by { |_, v| v }&.first
  end

  def over_under_prob(line = "2.5")
    over_under_probs&.dig(line.to_s)
  end

  def confidence_label
    case confidence_score.to_f
    when 0..33  then "niedrig"
    when 34..60 then "mittel"
    else             "hoch"
    end
  end

  def value_stars
    "★" * value_rating.to_i + "☆" * (5 - value_rating.to_i)
  end
end
