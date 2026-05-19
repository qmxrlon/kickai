class Match < ApplicationRecord
  belongs_to :league
  belongs_to :home_team, class_name: "Team"
  belongs_to :away_team, class_name: "Team"

  has_one    :prediction, dependent: :destroy
  has_one    :match_statistic, dependent: :destroy
  has_many   :betting_tips, dependent: :destroy

  # Match status
  enum :status, {
    scheduled: 0,
    in_progress: 1,
    finished: 2,
    postponed: 3,
    cancelled: 4
  }, default: :scheduled

  validates :scheduled_at, presence: true
  validates :external_id,  uniqueness: { allow_nil: true }

  scope :upcoming,    -> { scheduled.where("scheduled_at > ?", Time.current).order(scheduled_at: :asc) }
  scope :recent,      -> { finished.order(scheduled_at: :desc) }
  scope :today,       -> { where(scheduled_at: Time.current.beginning_of_day..Time.current.end_of_day) }
  scope :this_week,   -> { where(scheduled_at: Time.current.beginning_of_week..Time.current.end_of_week) }
  scope :with_prediction, -> { includes(:prediction).where.not(predictions: { id: nil }) }

  # ── Helpers ─────────────────────────────────────────────────────────────────

  def title
    "#{home_team.name} vs #{away_team.name}"
  end

  def result
    return nil unless finished?
    "#{home_score}:#{away_score}"
  end

  def outcome
    return nil unless finished?
    return "home"  if home_score > away_score
    return "away"  if away_score > home_score
    "draw"
  end

  def has_prediction?
    prediction.present?
  end

  # Head-to-head matches between these two teams (most recent first)
  STATUS_LABELS = {
    "scheduled"   => "Geplant",
    "in_progress" => "Läuft",
    "finished"    => "Beendet",
    "postponed"   => "Verschoben",
    "cancelled"   => "Abgesagt"
  }.freeze

  def status_label
    STATUS_LABELS.fetch(status.to_s, status.to_s.humanize)
  end

  def head_to_head(limit = 10)
    Match.finished
         .where(home_team: [home_team, away_team])
         .where(away_team: [home_team, away_team])
         .where.not(id: id)
         .order(scheduled_at: :desc)
         .limit(limit)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[status league_id home_team_id away_team_id scheduled_at home_score away_score]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[league home_team away_team prediction]
  end
end
