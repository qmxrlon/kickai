class SubscriptionPlan < ApplicationRecord
  # tier: free, basic, premium
  enum :tier, { free: 0, basic: 1, premium: 2 }, default: :free

  validates :name, presence: true, uniqueness: true
  validates :tier, presence: true

  # features is a JSONB column: { "predictions_1x2" => true, "ai_analysis" => true, ... }
  scope :active,   -> { where(active: true) }
  scope :visible,  -> { active.order(price_monthly_cents: :asc) }

  def price_display
    return "Kostenlos" if price_monthly_cents.to_i.zero?
    "#{(price_monthly_cents / 100.0).round(2).to_s.sub(".", ",")} €/Monat"
  end

  def feature?(key)
    features&.dig(key.to_s) == true
  end

  def stripe_price_id
    ENV["STRIPE_PRICE_#{tier.upcase}"]
  end
end
