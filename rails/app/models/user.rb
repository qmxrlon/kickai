class User < ApplicationRecord
  # Auth
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :trackable

  # Payments (Pay gem)
  pay_customer

  # Roles
  enum :role, { user: 0, premium: 1, admin: 2 }, default: :user

  # Associations
  has_many :betting_tips, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  # Subscription helpers
  def subscribed?
    payment_processor.subscribed? rescue false
  end

  def premium?
    role_before_type_cast >= 1 || subscribed?
  end

  def can_view_predictions?
    premium? || admin?
  end

  def can_view_full_analysis?
    role == "premium" || admin?
  end

  def active_subscription_plan
    return nil unless subscribed?
    payment_processor.subscription&.name
  end
end
