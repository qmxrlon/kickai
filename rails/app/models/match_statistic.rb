class MatchStatistic < ApplicationRecord
  belongs_to :match

  # stats column is a JSONB field holding all raw stats
  # structured as: { home: { shots: 12, shots_on_target: 5, ... }, away: { ... } }

  def home_stats
    stats&.dig("home") || {}
  end

  def away_stats
    stats&.dig("away") || {}
  end
end
