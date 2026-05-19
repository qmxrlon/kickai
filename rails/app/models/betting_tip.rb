class BettingTip < ApplicationRecord
  belongs_to :match
  belongs_to :user

  enum :tip_type, {
    one_x_two:  0,   # 1X2
    over_under: 1,
    btts:       2,
    correct_score: 3,
    other:      9
  }, default: :one_x_two

  enum :result, {
    pending: 0,
    won:     1,
    lost:    2,
    void:    3
  }, default: :pending

  validates :tip_value,  presence: true
  validates :odds,       presence: true, numericality: { greater_than: 1 }
  validates :stake,      numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  scope :published, -> { where(published: true) }
  scope :resolved,  -> { where.not(result: :pending) }

  def profit_loss
    return nil unless resolved?
    won? ? ((odds - 1) * stake.to_f).round(2) : -stake.to_f
  end

  def roi
    return nil if stake.to_f.zero? || !resolved?
    (profit_loss / stake.to_f * 100).round(1)
  end
end
