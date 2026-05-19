class Sport < ApplicationRecord
  has_many :leagues, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation :set_slug

  scope :active, -> { where(active: true) }

  def to_param
    slug
  end

  private

  def set_slug
    self.slug ||= name.to_s.parameterize if name.present?
  end
end
