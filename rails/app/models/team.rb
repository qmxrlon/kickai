class Team < ApplicationRecord
  belongs_to :league

  has_many :home_matches, class_name: "Match", foreign_key: :home_team_id, dependent: :nullify
  has_many :away_matches, class_name: "Match", foreign_key: :away_team_id, dependent: :nullify

  validates :name,        presence: true
  validates :external_id, uniqueness: { allow_nil: true }

  def matches
    Match.where("home_team_id = ? OR away_team_id = ?", id, id)
  end

  def recent_matches(limit = 10)
    matches.finished.order(scheduled_at: :desc).limit(limit)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[name short_name external_id league_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[league]
  end
end
