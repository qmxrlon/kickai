class League < ApplicationRecord
  belongs_to :sport

  has_many :teams,   dependent: :destroy
  has_many :matches, dependent: :destroy

  validates :name,        presence: true
  validates :country,     presence: true
  validates :external_id, uniqueness: { allow_nil: true }

  scope :active, -> { where(active: true) }
  scope :for_sport, ->(sport) { joins(:sport).where(sports: { slug: sport }) }

  def display_name
    "#{country} – #{name}"
  end

  COUNTRY_FLAGS = {
    "Deutschland" => "🇩🇪", "England" => "🏴󠁧󠁢󠁥󠁮󠁧󠁿", "Spanien" => "🇪🇸",
    "Italien"     => "🇮🇹", "Frankreich" => "🇫🇷", "Portugal" => "🇵🇹",
    "Niederlande" => "🇳🇱", "Europa" => "🇪🇺"
  }.freeze

  def flag_emoji
    COUNTRY_FLAGS.fetch(country, "🏳")
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[name country external_id active sport_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[sport]
  end
end
